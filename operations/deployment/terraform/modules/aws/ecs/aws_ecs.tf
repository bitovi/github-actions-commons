resource "aws_ecs_cluster" "cluster" {
  name = var.aws_ecs_cluster_name != null ? var.aws_ecs_cluster_name : "${var.aws_resource_identifier}-cluster"
  tags = {
    Name = "${var.aws_resource_identifier}-ecs-cluster"
  }
}

resource "aws_ecs_task_definition" "ecs_task" {
  family                   = local.aws_ecs_task_name
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = tonumber(var.aws_ecs_app_cpu)
  memory                   = tonumber(var.aws_ecs_app_mem)

  container_definitions = <<DEFINITION
[
  {
    "image": "${var.aws_ecs_app_image}",
    "cpu": ${var.aws_ecs_app_cpu},
    "memory": ${var.aws_ecs_app_mem},
    "name": "${local.aws_ecs_task_name}",
    "networkMode": "awsvpc",
    "portMappings": [
      {
        "containerPort": ${var.aws_ecs_container_port},
        "hostPort": ${local.aws_ecs_container_port}
      }
    ]
  }
]
DEFINITION
}

resource "aws_ecs_service" "ecs_service_with_lb" {
  name             = var.aws_ecs_service_name != null ? var.aws_ecs_service_name : "${var.aws_resource_identifier}-service"
  cluster          = aws_ecs_cluster.cluster.id
  task_definition  = aws_ecs_task_definition.ecs_task.arn
  desired_count    = tonumber(var.aws_ecs_node_count)
  launch_type      = "FARGATE"

  network_configuration {
    security_groups  = [aws_security_group.ecs_sg.id]
    subnets          = var.aws_selected_subnets
    assign_public_ip = var.aws_ecs_assign_public_ip
  }

  load_balancer {
    target_group_arn = aws_alb_target_group.lb_targets.id
    container_name   = var.aws_ecs_app_image
    container_port   = local.aws_ecs_container_port[0]
  }
  depends_on = [aws_lb_listener.hello_world]
}

#resource "aws_ecs_service" "ecs_service_no_lb" {
#  name             = var.aws_ecs_service_name != null ? var.aws_ecs_service_name : "${var.aws_resource_identifier}-service"
#  cluster          = aws_ecs_cluster.cluster.id
#  task_definition  = aws_ecs_task_definition.ecs_task.arn
#  desired_count    = var.aws_ecs_node_count
#  assign_public_ip = var.aws_ecs_assign_public_ip
#  launch_type      = "FARGATE"
#
#  network_configuration {
#    security_groups  = [aws_security_group.ecs_sg.id]
#    subnets          = var.aws_selected_subnets
#    assign_public_ip = true
#  }
#
#  depends_on = [aws_lb_listener.hello_world]
#}



locals {
  aws_ecs_task_name      = var.aws_ecs_task_name != null ? var.aws_ecs_task_name : "${var.aws_resource_identifier}-app"
  aws_ecs_container_port = var.aws_ecs_container_port != "" ? [for n in split(",", var.aws_ecs_container_port) : tonumber(n)] : []
  aws_ecs_lb_port        = var.aws_ecs_lb_port != "" ?        [for n in split(",", var.aws_ecs_container_port) : tonumber(n)] : local.aws_ecs_container_port
}

# Network part
resource "aws_security_group" "ecs_sg" {
  name        = var.aws_ecs_security_group_name != "" ? var.aws_ecs_security_group_name : "SG for ${var.aws_resource_identifier} - ECS"
  description = "SG for ${var.aws_resource_identifier} - ECS"
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

#resource "aws_security_group_rule" "incoming_ecs_ports" {
#  count       = length(local.aws_ecs_container_port)
#  type        = "ingress"
#  from_port   = local.aws_ecs_container_port[count.index]
#  to_port     = local.aws_ecs_container_port[count.index]
#  protocol    = "tcp"
#  cidr_blocks = ["0.0.0.0/0"]
#  security_group_id = aws_security_group.ecs_sg.id
#}

resource "aws_security_group_rule" "incoming_alb" {
  count                    = length(local.aws_ecs_container_port)
  type                     = "ingress"
  from_port                = local.aws_ecs_container_port[count.index]
  to_port                  = local.aws_ecs_container_port[count.index]
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.ecs_lb_sg.id
  security_group_id        = aws_security_group.ecs_sg.id
}


### ALB --- Make this optional -- Using ALB name intentionally. (To make clear is an A LB)

resource "aws_alb" "ecs_lb" {
  name            = var.aws_ecs_lb_name != null ? var.aws_ecs_lb_name : "${var.aws_resource_identifier}-ecs-lb"
  subnets         = var.aws_selected_subnets
  security_groups = [aws_security_group.ecs_lb_sg.id]
}

resource "aws_alb_target_group" "lb_targets" {
  count       = length(local.aws_ecs_container_port)
  name        = "${var.aws_resource_identifier}-ecs-tagets-${var.aws_ecs_container_port[count.index]}"
  port        = var.aws_ecs_container_port[count.index]
  protocol    = "HTTP"
  vpc_id      = var.aws_selected_vpc_id
  target_type = "ip"
}

# Redirect all traffic from the ALB to the target group
resource "aws_alb_listener" "lb_listener" {
  count       = length(local.aws_ecs_lb_port)
  load_balancer_arn = "${aws_alb.ecs_lb.id}"
  port              = local.aws_ecs_lb_port[count.index]
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_alb_target_group.lb_targets.id
    type             = "forward"
  }
}

resource "aws_security_group" "ecs_lb_sg" {
  name        = var.aws_ecs_security_group_name != "" ? "${var.aws_ecs_security_group_name}-lb" : "SG for ${var.aws_resource_identifier} - ECS LB"
  description = "SG for ${var.aws_resource_identifier} - ECS Load Balancer"
  vpc_id      = var.aws_selected_vpc_id

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group_rule" "incoming_ecs_lb_ports" {
  count       = length(local.aws_ecs_lb_port)
  type        = "ingress"
  from_port   = local.aws_ecs_lb_port[count.index]
  to_port     = local.aws_ecs_container_port[count.index]
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = aws_security_group.ecs_lb_sg.id
}

output "load_balancer_dns" {
  value = aws_alb.ecs_lb.dns_name
}