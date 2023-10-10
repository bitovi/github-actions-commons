locals {
  aws_ecs_container_port    = [for n in split(",", var.aws_ecs_container_port) : tonumber(n)]
  aws_ecs_sg_container_port = distinct(local.aws_ecs_container_port)
  aws_ecs_lb_port           = var.aws_ecs_lb_port != "" ?  [for n in split(",", var.aws_ecs_lb_port) : tonumber(n)] : local.aws_ecs_container_port
  aws_ecs_sg_lb_port        = distinct(local.aws_ecs_lb_port)
  aws_ecs_image_path       = var.aws_ecs_image_path != "" ? [for n in split(",", var.aws_ecs_image_path) : n ] : []
}

# Network part
resource "aws_security_group" "ecs_sg" {
  name        = var.aws_ecs_security_group_name != "" ? var.aws_ecs_security_group_name : "SG for ${var.aws_resource_identifier} ECS"
  description = "SG for ${var.aws_resource_identifier} - ${local.aws_ecs_task_name} - ECS"
  vpc_id      = var.aws_selected_vpc_id
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "${var.aws_resource_identifier}-ecs-sg"
  }
}

resource "aws_security_group_rule" "incoming_alb" {
  count                    = length(local.aws_ecs_sg_container_port)
  type                     = "ingress"
  from_port                = local.aws_ecs_sg_container_port[count.index]
  to_port                  = local.aws_ecs_sg_container_port[count.index]
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.ecs_lb_sg.id
  security_group_id        = aws_security_group.ecs_sg.id
}

### ALB --- Make this optional -- Using ALB name intentionally. (To make clear is an A LB)

resource "aws_alb" "ecs_lb" {
  name            = var.aws_resource_identifier_supershort
  subnets         = var.aws_selected_subnets
  security_groups = [aws_security_group.ecs_lb_sg.id]

  tags = {
    Name = "${var.aws_resource_identifier_supershort}"
  }
}

resource "aws_alb_target_group" "lb_targets" {
  count       = length(local.aws_ecs_container_port)
  name        = "${var.aws_resource_identifier_supershort}${count.index}"
  port        = local.aws_ecs_container_port[count.index]
  protocol    = "HTTP"
  vpc_id      = var.aws_selected_vpc_id
  target_type = "ip"

  lifecycle {
    replace_triggered_by = [aws_security_group.ecs_sg]
  }
}

# Redirect all traffic from the ALB to the target group
resource "aws_alb_listener" "lb_listener" {
  count             = length(local.aws_ecs_lb_port)
  load_balancer_arn = "${aws_alb.ecs_lb.id}"
  port              = local.aws_ecs_lb_port[count.index]
  protocol          = var.aws_certificates_selected_arn != "" ? "HTTPS" : "HTTP"
  certificate_arn   = var.aws_certificates_selected_arn
  ssl_policy        = var.aws_certificates_selected_arn != "" ? "ELBSecurityPolicy-TLS13-1-2-2021-06" : "" # https://docs.aws.amazon.com/elasticloadbalancing/latest/application/create-https-listener.html
  default_action {
    target_group_arn = aws_alb_target_group.lb_targets[count.index].id
    type             = "forward"
  }
}

resource "aws_alb_listener_rule" "redirect_based_on_path" {
  count        = length(local.aws_ecs_image_path)
  listener_arn = aws_alb_listener.lb_listener[0].arn

  action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.lb_targets[count.index + 1].arn
  }

  condition {
    path_pattern {
      values = ["/${local.aws_ecs_image_path[count.index]}/*"]
    }
  }
}

resource "aws_alb_listener" "http_redirect" {
  #count             = var.aws_ecs_lb_redirect_enable && !contains(local.aws_ecs_lb_port,80) ? 1 : 0
  load_balancer_arn = "${aws_alb.ecs_lb.id}"
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_alb_target_group.lb_targets[0].id
    type             = "forward"
  }
#  default_action {
#    type = "redirect"
#
#    redirect {
#      port        = local.aws_ecs_lb_port[0]
#      protocol    = var.aws_certificates_selected_arn != "" ? "HTTPS" : "HTTP"
#      status_code = "HTTP_301"
#    }
#  }
}

resource "aws_alb_listener" "https_redirect" {
  #count             = var.aws_ecs_lb_redirect_enable && var.aws_certificates_selected_arn != "" && !contains(local.aws_ecs_lb_port,443) ? 1 : 0
  load_balancer_arn = "${aws_alb.ecs_lb.id}"
  port              = "443"
  protocol          = "HTTPS"
  certificate_arn   = var.aws_certificates_selected_arn
  ssl_policy        = var.aws_certificates_selected_arn != "" ? "ELBSecurityPolicy-TLS13-1-2-2021-06" : "" # https://docs.aws.amazon.com/elasticloadbalancing/latest/application/create-https-listener.html

  default_action {
    target_group_arn = aws_alb_target_group.lb_targets[0].id
    type             = "forward"
  }

#  default_action {
#    type = "redirect"
#
#    redirect {
#      port        = local.aws_ecs_lb_port[0]
#      protocol    = "HTTPS"
#      status_code = "HTTP_301"
#    }
#  }
}

resource "aws_security_group" "ecs_lb_sg" {
  name        = var.aws_ecs_security_group_name != "" ? "${var.aws_ecs_security_group_name}-lb" : "SG for ${var.aws_resource_identifier} ECS LB"
  description = "SG for ${var.aws_resource_identifier} - ${local.aws_ecs_task_name} ECS Load Balancer"
  vpc_id      = var.aws_selected_vpc_id

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "${var.aws_resource_identifier}-ecs-lb-sg"
  }
}

resource "aws_security_group_rule" "incoming_ecs_lb_ports" {
  count       = length(local.aws_ecs_sg_lb_port)
  type        = "ingress"
  from_port   = local.aws_ecs_sg_lb_port[count.index]
  to_port     = local.aws_ecs_sg_lb_port[count.index]
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = aws_security_group.ecs_lb_sg.id
}

output "load_balancer_dns" {
  value = aws_alb.ecs_lb.dns_name
}

output "load_balancer_port" {
  value = aws_alb_listener.lb_listener[0].port
}

output "load_balancer_protocol" {
  value = aws_alb_listener.lb_listener[0].protocol
}

output "load_balancer_zone_id" {
  value = aws_alb.ecs_lb.zone_id
}