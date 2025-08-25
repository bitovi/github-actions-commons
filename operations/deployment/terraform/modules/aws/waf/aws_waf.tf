### WAF Configuration
resource "aws_wafv2_web_acl" "waf" {
  count = var.aws_waf_enable ? 1 : 0
  name  = "${var.aws_resource_identifier}-waf"
  description = "WAF for ${var.aws_resource_identifier}"
  scope = "REGIONAL"

  default_action {
    allow {}
  }

  tags = {
    Name = "${var.aws_resource_identifier}-waf"
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.aws_resource_identifier}-waf"
    sampled_requests_enabled   = true
  }
}

# Associate WAF with ALB
resource "aws_wafv2_web_acl_association" "waf_association" {
  count        = var.aws_waf_enable ? 1 : 0
  resource_arn = var.aws_lb_resource_arn
  web_acl_arn  = aws_wafv2_web_acl.waf[0].arn
}

# WAF Logging Configuration (optional)
resource "aws_wafv2_web_acl_logging_configuration" "waf_logging" {
  count                   = var.aws_waf_enable && var.aws_waf_logging_enable ? 1 : 0
  resource_arn            = aws_wafv2_web_acl.waf[0].arn
  log_destination_configs = [aws_cloudwatch_log_group.waf_log_group[0].arn]

  redacted_fields {
    single_header {
      name = "authorization"
    }
  }

  redacted_fields {
    single_header {
      name = "cookie"
    }
  }
}

# CloudWatch Log Group for WAF (optional)
resource "aws_cloudwatch_log_group" "waf_log_group" {
  count             = var.aws_waf_enable && var.aws_waf_logging_enable ? 1 : 0
  name              = "/aws/wafv2/${var.aws_resource_identifier}"
  retention_in_days = var.aws_waf_log_retention_days

  tags = {
    Name = "${var.aws_resource_identifier}-waf-logs"
  }
}

# ...existing code...

# Add WAF outputs
output "waf_web_acl_arn" {
  value = var.aws_waf_enable ? aws_wafv2_web_acl.waf[0].arn : null
}

output "waf_web_acl_id" {
  value = var.aws_waf_enable ? aws_wafv2_web_acl.waf[0].id : null
}