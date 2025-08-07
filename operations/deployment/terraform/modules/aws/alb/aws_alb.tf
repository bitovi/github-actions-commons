data "aws_elb_service_account" "main" {}

# S3 bucket for ALB access logs
resource "aws_s3_bucket" "lb_access_logs" {
  bucket        = var.aws_elb_access_log_bucket_name
  force_destroy = true
  tags = {
    Name = var.aws_elb_access_log_bucket_name
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "lb_access_logs_lifecycle" {
  count  = tonumber(var.aws_elb_access_log_expire) > 0 ? 1 : 0
  bucket = aws_s3_bucket.lb_access_logs.id
  rule {
    id     = "ExpirationRule"
    status = "Enabled"
    expiration {
      days = tonumber(var.aws_elb_access_log_expire)
    }
  }
}

resource "aws_s3_bucket_policy" "allow_access_from_elb_account" {
  bucket = aws_s3_bucket.lb_access_logs.id
  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Id": "Policy",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": ["${data.aws_elb_service_account.main.arn}"]
      },
      "Action": ["s3:PutObject"],
      "Resource": "arn:aws:s3:::${var.aws_elb_access_log_bucket_name}/*"
    }
  ]
}
POLICY
  lifecycle {
    ignore_changes = [policy]
  }
}

# ALB Security Group
resource "aws_security_group" "alb_security_group" {
  name        = var.aws_elb_security_group_name != "" ? "${var.aws_elb_security_group_name}-alb" : "SG for ${var.aws_resource_identifier} - ALB"
  description = "SG for ${var.aws_resource_identifier} - ALB"
  vpc_id      = var.aws_vpc_selected_id
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "${var.aws_resource_identifier}-alb"
  }
}

# Security group rule to allow traffic from ALB to target
resource "aws_security_group_rule" "incoming_alb" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = -1
  source_security_group_id = aws_security_group.alb_security_group.id
  security_group_id        = var.aws_elb_target_sg_id
}

# ALB Security Group Rules for incoming connections
resource "aws_security_group_rule" "incoming_alb_ports" {
  count             = local.aws_ports_amount
  type              = "ingress"
  from_port         = local.aws_alb_listen_port[count.index]
  to_port           = local.aws_alb_listen_port[count.index]
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.alb_security_group.id
}

# Application Load Balancer
resource "aws_lb" "alb" {
  name               = var.aws_resource_identifier_supershort
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_security_group.id]
  subnets            = local.alb_subnets

  enable_deletion_protection = false

  access_logs {
    bucket  = aws_s3_bucket.lb_access_logs.id
    prefix  = "alb"
    enabled = true
  }

  tags = {
    Name = "${var.aws_resource_identifier_supershort}"
  }
}

# ALB Target Group
resource "aws_lb_target_group" "alb_targets" {
  count    = length(local.aws_alb_app_port)
  name     = "${var.aws_resource_identifier_supershort}${count.index}"
  port     = local.aws_alb_app_port[count.index]
  protocol = local.alb_app_protocol[count.index]
  vpc_id   = var.aws_vpc_selected_id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    path                = local.health_check_path[count.index]
    matcher             = "200"
    protocol            = local.alb_app_protocol[count.index]
    port                = "traffic-port"
  }

  tags = {
    Name = "${var.aws_resource_identifier_supershort}-tg-${count.index}"
  }
}

# ALB Target Group Attachment
resource "aws_lb_target_group_attachment" "alb_target_attachment" {
  count            = length(local.aws_alb_app_port)
  target_group_arn = aws_lb_target_group.alb_targets[count.index].arn
  target_id        = var.aws_instance_server_id
  port             = local.aws_alb_app_port[count.index]
}

# ALB Listeners
resource "aws_lb_listener" "alb_listener" {
  count             = length(local.listener_for_each)
  load_balancer_arn = aws_lb.alb.arn
  port              = local.aws_alb_listen_port[count.index]
  protocol          = local.alb_listen_protocol[count.index]
  ssl_policy        = local.alb_ssl_available && local.alb_listen_protocol[count.index] == "HTTPS" ? "ELBSecurityPolicy-TLS13-1-2-2021-06" : null
  certificate_arn   = local.alb_ssl_available && local.alb_listen_protocol[count.index] == "HTTPS" ? var.aws_certificates_selected_arn : null

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb_targets[count.index].arn
  }
}

# Locals for processing variables
locals {
  # Check if there is a cert available
  alb_ssl_available = var.aws_certificates_selected_arn != "" ? true : false

  # Transform CSV values into arrays
  aws_alb_listen_port = var.aws_elb_listen_port != "" ? [for n in split(",", var.aws_elb_listen_port) : tonumber(n)] : (local.alb_ssl_available ? [443] : [80])
  aws_alb_app_port    = var.aws_elb_app_port != "" ? [for n in split(",", var.aws_elb_app_port) : tonumber(n)] : var.aws_elb_listen_port != "" ? local.aws_alb_listen_port : [3000]
  aws_alb_app_protocol = var.aws_elb_app_protocol != "" ? [for n in split(",", var.aws_elb_app_protocol) : upper(n)] : []

  # Store the lowest array length
  aws_ports_amount = length(local.aws_alb_listen_port) < length(local.aws_alb_app_port) ? length(local.aws_alb_listen_port) : length(local.aws_alb_app_port)

  # Store the shortest array for listener creation
  listener_for_each = length(local.aws_alb_listen_port) < length(local.aws_alb_app_port) ? local.aws_alb_listen_port : local.aws_alb_app_port

  # Protocol handling
  alb_app_protocol    = length(local.aws_alb_app_protocol) < local.aws_ports_amount ? [for _ in range(local.aws_ports_amount) : "HTTP"] : local.aws_alb_app_protocol
  alb_listen_protocol = local.alb_ssl_available ? [for _ in range(local.aws_ports_amount) : "HTTPS"] : [for _ in range(local.aws_ports_amount) : "HTTP"]

  # Health check path extraction from healthcheck string
  health_check_path = [for i in range(length(local.aws_alb_app_port)) : 
    can(regex("^HTTP:", var.aws_elb_healthcheck)) ? 
      try(split(":", var.aws_elb_healthcheck)[1], "/") : 
      "/"
  ]

  # ALB subnets - use provided subnets or fall back to single subnet
  alb_subnets = length(var.aws_alb_subnets) > 0 ? var.aws_alb_subnets : [var.aws_vpc_subnet_selected]
}

# Outputs
output "aws_elb_dns_name" {
  value = aws_lb.alb.dns_name
}

output "aws_elb_zone_id" {
  value = aws_lb.alb.zone_id
}

output "alb_arn" {
  value = aws_lb.alb.arn
}

output "alb_target_group_arns" {
  value = aws_lb_target_group.alb_targets[*].arn
}
