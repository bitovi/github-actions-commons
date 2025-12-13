# Locals for ALB
locals {
  alb_ssl_available = var.aws_certificates_selected_arn != "" ? true : false

  alb_listen_port_list = var.aws_alb_listen_port != "" ? [for n in split(",", var.aws_alb_listen_port) : tonumber(n)] : []

  alb_listen_port     = var.aws_alb_listen_port != "" ? [for n in split(",", var.aws_alb_listen_port) : tonumber(n)] : var.aws_certificate_enabled ? [443] : [80]
  alb_listen_protocol = var.aws_alb_listen_protocol != "" ? [for n in split(",", var.aws_alb_listen_protocol) : n] : var.aws_certificate_enabled ? ["HTTPS"] : ["HTTP"]
  alb_app_port        = var.aws_alb_app_port != "" ? [for n in split(",", var.aws_alb_app_port) : tonumber(n)] : local.alb_listen_port
  alb_app_protocol    = var.aws_alb_app_protocol != "" ? [for n in split(",", var.aws_alb_app_protocol) : n] : [for _ in local.alb_app_port : "HTTP"]

  # Ensure all arrays have the same length
  alb_ports_ammount = min(
    length(local.alb_listen_port),
    length(local.alb_app_port),
    length(local.alb_listen_protocol),
    length(local.alb_app_protocol)
  )
}


# Security group for ALB
resource "aws_security_group" "alb_security_group" {
  name        = var.aws_alb_security_group_name != "" ? var.aws_alb_security_group_name : "SG for ${var.aws_resource_identifier} - ALB"
  description = "SG for ${var.aws_resource_identifier} - ALB"
  vpc_id      = var.aws_vpc_selected_id
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "${var.aws_resource_identifier}-alb-sg"
  }
}

# Allow all from ALB to target SG
resource "aws_security_group_rule" "incoming_alb" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = -1
  source_security_group_id = aws_security_group.alb_security_group.id
  security_group_id        = var.aws_alb_target_sg_id
}

# Allow incoming connections to the ALB
resource "aws_security_group_rule" "incoming_alb_ports" {
  count             = local.alb_ports_ammount
  type              = "ingress"
  from_port         = local.alb_listen_port[count.index]
  to_port           = local.alb_listen_port[count.index]
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.alb_security_group.id
}

# ALB resource (conditionally enable access logs)
resource "aws_lb" "vm_alb" {
  name               = var.aws_resource_identifier_supershort
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_security_group.id]
  subnets            = var.aws_vpc_subnet_selected

  dynamic "access_logs" {
    for_each = var.aws_alb_access_log_enabled ? [1] : []
    content {
      bucket  = aws_s3_bucket.alb_access_logs[0].id
      enabled = true
    }
  }

  idle_timeout = 400

  tags = {
    Name = "${var.aws_resource_identifier_supershort}-alb"
  }
}

# Target groups for ALB
resource "aws_lb_target_group" "vm_alb_tg" {
  count    = local.alb_ports_ammount
  name     = "${var.aws_resource_identifier_supershort}${count.index}"
  port     = local.alb_app_port[count.index]
  protocol = local.alb_app_protocol[count.index]
  vpc_id   = var.aws_vpc_selected_id

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    path                = var.aws_alb_healthcheck_path
    protocol            = var.aws_alb_healthcheck_protocol
    interval            = 30
  }

  lifecycle {
    replace_triggered_by = [aws_security_group.alb_security_group.id]
  }

  tags = {
    Name = "${var.aws_resource_identifier_supershort}-${count.index}-${local.alb_app_port[count.index]}"
  }
}

# Always exists, acts as a safe dependency wrapper
resource "null_resource" "http_redirect_dep" {
  triggers = {
    id = (
      length(aws_alb_listener.http_redirect) > 0
    ) ? aws_alb_listener.http_redirect[0].id : "none"
  }
}

# Listeners for ALB
resource "aws_alb_listener" "lb_listener_ssl" {
  count             = var.aws_certificate_enabled ? local.alb_ports_ammount : 0
  load_balancer_arn = aws_lb.vm_alb.arn
  port              = local.alb_listen_port[count.index]
  protocol          = local.alb_listen_protocol[count.index]

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.vm_alb_tg[count.index].arn
  }
  # https://docs.aws.amazon.com/elasticloadbalancing/latest/application/create-https-listener.html
  ssl_policy      = var.aws_alb_ssl_policy
  certificate_arn = var.aws_certificates_selected_arn
  lifecycle {
    replace_triggered_by = [null_resource.http_redirect_dep.id]
  }
  depends_on = [aws_alb_listener.http_redirect]
}

resource "aws_alb_listener" "lb_listener" {
  count             = var.aws_certificate_enabled ? 0 : local.alb_ports_ammount
  load_balancer_arn = aws_lb.vm_alb.arn
  port              = local.alb_listen_port[count.index]
  protocol          = local.alb_listen_protocol[count.index]
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.vm_alb_tg[count.index].arn
  }
  lifecycle {
    replace_triggered_by = [null_resource.http_redirect_dep.id]
  }
  depends_on = [aws_alb_listener.http_redirect]
}

resource "aws_alb_listener" "http_redirect" {
  count             = var.aws_alb_redirect_enable && !contains(local.alb_listen_port, 80) ? var.aws_certificates_selected_arn != "" ? 1 : 0 : 0 #!contains(local.alb_listen_port, 80) ? 1 : 0 : 0
  load_balancer_arn = aws_lb.vm_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
  depends_on = [
    aws_lb.vm_alb,
    aws_lb_target_group.vm_alb_tg
  ]
}

resource "aws_alb_listener" "http_forward" {
  count             = var.aws_alb_redirect_enable && !var.aws_alb_www_to_apex_redirect && !contains(local.alb_listen_port, 80) ? 1 : 0 # && !var.aws_certificate_enabled && #!contains(local.alb_listen_port, 80) ? 1 : 0 : 0
  load_balancer_arn = aws_lb.vm_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.vm_alb_tg[0].arn
  }
  depends_on = [
    aws_lb.vm_alb,
    aws_lb_target_group.vm_alb_tg
  ]
}

resource "aws_alb_listener" "http_www_redirect" {
  count             = var.aws_alb_redirect_enable && var.aws_alb_www_to_apex_redirect && !var.aws_certificate_enabled ? !contains(local.alb_listen_port, 80) ? 1 : 0 : 0
  load_balancer_arn = aws_lb.vm_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "Not Found"
      status_code  = "404"
    }
  }
  depends_on = [
    aws_lb.vm_alb,
    aws_lb_target_group.vm_alb_tg
  ]
}

resource "aws_lb_listener_rule" "http_forward_apex" {
  count        = var.aws_alb_www_to_apex_redirect && var.aws_r53_domain_name != "" && !var.aws_certificate_enabled && length(aws_alb_listener.http_www_redirect) > 0 ? 1 : 0
  listener_arn = aws_alb_listener.http_www_redirect[0].arn
  priority     = 20

  condition {
    host_header {
      values = [var.aws_r53_domain_name]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.vm_alb_tg[0].id
  }
}

resource "aws_lb_listener_rule" "redirect_www_to_apex" {
  count        = var.aws_alb_www_to_apex_redirect && var.aws_r53_domain_name != "" && (var.aws_certificate_enabled ? length(aws_alb_listener.https_redirect) > 0 : length(aws_alb_listener.http_www_redirect) > 0) ? 1 : 0
  listener_arn = var.aws_certificate_enabled ? aws_alb_listener.https_redirect[0].arn : aws_alb_listener.http_www_redirect[0].arn
  priority     = 10

  condition {
    host_header {
      values = ["www.${var.aws_r53_domain_name}"]
    }
  }

  action {
    type = "redirect"

    redirect {
      port        = local.alb_ssl_available ? "443" : "80"
      protocol    = local.alb_ssl_available ? "HTTPS" : "HTTP"
      status_code = "HTTP_301"
      host        = var.aws_r53_domain_name
      path        = "/#{path}"
      query       = "#{query}"
    }
  }
}

resource "aws_security_group_rule" "incoming_alb_http" {
  count             = !contains(local.alb_listen_port, 80) ? length(aws_alb_listener.http_redirect) + length(aws_alb_listener.http_forward) + length(aws_alb_listener.http_www_redirect) : 0
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.alb_security_group.id
}

resource "aws_security_group_rule" "incoming_alb_https" {
  count             = !contains(local.alb_listen_port, 443) ? length(aws_alb_listener.https_redirect) : 0
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.alb_security_group.id
}
###

resource "aws_alb_listener" "https_redirect" {
  count             = var.aws_alb_redirect_enable && var.aws_certificate_enabled && !contains(local.alb_listen_port, 443) ? 1 : 0 #!contains(local.alb_listen_port, 443) ? 1 : 0 : 0
  load_balancer_arn = aws_lb.vm_alb.arn
  port              = "443"
  protocol          = "HTTPS"
  certificate_arn   = var.aws_certificates_selected_arn
  ssl_policy        = var.aws_certificates_selected_arn != "" ? var.aws_alb_ssl_policy : "" # https://docs.aws.amazon.com/elasticloadbalancing/latest/application/create-https-listener.html

  default_action {
    target_group_arn = aws_lb_target_group.vm_alb_tg[0].arn
    type             = "forward"
  }
}

# Attach EC2 instance(s) to target group(s)
resource "aws_lb_target_group_attachment" "vm_alb_attachment" {
  count            = local.alb_ports_ammount
  target_group_arn = aws_lb_target_group.vm_alb_tg[count.index].arn
  target_id        = var.aws_instance_server_id
  port             = local.alb_app_port[count.index]
}


# S3 bucket for ALB access logs (created only if logging is enabled)
resource "aws_s3_bucket" "alb_access_logs" {
  count         = var.aws_alb_access_log_enabled ? 1 : 0
  bucket        = var.aws_alb_access_log_bucket_name
  force_destroy = true
  tags = {
    Name = var.aws_alb_access_log_bucket_name
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "alb_access_logs_lifecycle" {
  count  = var.aws_alb_access_log_enabled && tonumber(var.aws_alb_access_log_expire) > 0 ? 1 : 0
  bucket = aws_s3_bucket.alb_access_logs[0].id
  rule {
    id     = "ExpirationRule"
    status = "Enabled"
    filter {
      prefix = ""
    }
    expiration {
      days = tonumber(var.aws_alb_access_log_expire)
    }
  }
}

data "aws_elb_service_account" "main" {
  count = var.aws_alb_access_log_enabled ? 1 : 0
}

resource "aws_s3_bucket_policy" "allow_access_from_another_account" {
  count  = var.aws_alb_access_log_enabled ? 1 : 0
  bucket = aws_s3_bucket.alb_access_logs[0].id
  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Id": "Policy",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": ["${data.aws_elb_service_account.main[0].arn}"]
      },
      "Action": ["s3:PutObject"],
      "Resource": "arn:aws:s3:::${var.aws_alb_access_log_bucket_name}/*"
    }
  ]
}
POLICY
  lifecycle {
    ignore_changes = [policy]
  }
}

# Outputs
output "aws_alb_dns_name" {
  value = aws_lb.vm_alb.dns_name
}
output "aws_alb_zone_id" {
  value = aws_lb.vm_alb.zone_id
}
output "aws_lb_resource_arn" {
  value = aws_lb.vm_alb.arn
}