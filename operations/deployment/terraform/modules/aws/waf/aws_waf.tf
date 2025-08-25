locals {
  aws_waf_rule_geo_block_countries = var.aws_waf_rule_geo_block_countries != "" ? [
    for n in split(",", var.aws_waf_rule_geo_block_countries) : (n)
  ] : []

  aws_waf_rule_geo_allow_only_countries = var.aws_waf_rule_geo_allow_only_countries != "" ? [
    for n in split(",", var.aws_waf_rule_geo_allow_only_countries) : (n)
  ] : []
}

### WAF Configuration
resource "aws_wafv2_web_acl" "waf" {
  count = var.aws_waf_enable ? 1 : 0
  name  = "${var.aws_resource_identifier}-waf"
  description = "WAF for ${var.aws_resource_identifier}"
  scope = "REGIONAL"

  default_action {
    allow {}
  }

  # Rate limiting rule
  dynamic "rule" {
    for_each = var.aws_waf_rule_rate_limit != "" ? [1] : []
    content {
      name     = "RateLimitRule"
      priority = 10

      action {
        block {}
      }

      statement {
        rate_based_statement {
          limit              = tonumber(var.aws_waf_rule_rate_limit)
          aggregate_key_type = "IP"
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = "RateLimitRule"
        sampled_requests_enabled   = true
      }
    }
  }

  # AWS Managed Core Rule Set
  dynamic "rule" {
    for_each = var.aws_waf_rule_managed_rules ? [1] : []
    content {
      name     = "AWSManagedRulesCommonRuleSet"
      priority = 20

      override_action {
        none {}
      }

      statement {
        managed_rule_group_statement {
          name        = "AWSManagedRulesCommonRuleSet"
          vendor_name = "AWS"
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = "AWSManagedRulesCommonRuleSetMetric"
        sampled_requests_enabled   = true
      }
    }
  }

  # AWS Managed Known Bad Inputs Rule Set
  dynamic "rule" {
    for_each = var.aws_waf_rule_managed_bad_inputs ? [1] : []
    content {
      name     = "AWSManagedRulesKnownBadInputsRuleSet"
      priority = 30

      override_action {
        none {}
      }

      statement {
        managed_rule_group_statement {
          name        = "AWSManagedRulesKnownBadInputsRuleSet"
          vendor_name = "AWS"
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = "AWSManagedRulesKnownBadInputsRuleSetMetric"
        sampled_requests_enabled   = true
      }
    }
  }

  # IP reputation rule
  dynamic "rule" {
    for_each = var.aws_waf_rule_ip_reputation ? [1] : []
    content {
      name     = "AWSManagedRulesAmazonIpReputationList"
      priority = 40

      override_action {
        none {}
      }

      statement {
        managed_rule_group_statement {
          name        = "AWSManagedRulesAmazonIpReputationList"
          vendor_name = "AWS"
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = "AWSManagedRulesAmazonIpReputationListMetric"
        sampled_requests_enabled   = true
      }
    }
  }

  # Anonymous IPs
  dynamic "rule" {
    for_each = var.aws_waf_rule_anonymous_ip ? [1] : []
    content {
      name     = "AWSManagedRulesAnonymousIpList"
      priority = 50

      override_action {
        none {}
      }

      statement {
        managed_rule_group_statement {
          name        = "AWSManagedRulesAnonymousIpList"
          vendor_name = "AWS"
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = "AWSManagedRulesAnonymousIpListMetric"
        sampled_requests_enabled   = true
      }
    }
  }

  # Bot Control (extra cost)
  dynamic "rule" {
    for_each = var.aws_waf_rule_bot_control ? [1] : []
    content {
      name     = "AWSManagedRulesBotControlRuleSet"
      priority = 60

      override_action {
        none {}
      }

      statement {
        managed_rule_group_statement {
          name        = "AWSManagedRulesBotControlRuleSet"
          vendor_name = "AWS"
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = "AWSManagedRulesBotControlRuleSetMetric"
        sampled_requests_enabled   = true
      }
    }
  }

  # Geo-Blocking Rule
  dynamic "rule" {
    for_each = length(local.aws_waf_rule_geo_block_countries) > 0 ? [1] : []
    content {
      name     = "GeoBlockRule"
      priority = 70

      action {
        block {}
      }

      statement {
        geo_match_statement {
          country_codes = local.aws_waf_rule_geo_block_countries
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = "GeoBlockRule"
        sampled_requests_enabled   = true
      }
    }
  }

  # Geo-Allow-Only Rule
  dynamic "rule" {
    for_each = length(local.aws_waf_rule_geo_allow_only_countries) > 0 ? [1] : []
    content {
      name     = "GeoAllowOnlyRule"
      priority = 75

      action {
        block {}
      }

      statement {
        not_statement {
          statement {
            geo_match_statement {
              country_codes = local.aws_waf_rule_geo_allow_only_countries
            }
          }
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = "GeoAllowOnlyRule"
        sampled_requests_enabled   = true
      }
    }
  }

  # User-Defined Rule Group
  dynamic "rule" {
    for_each = var.aws_waf_rule_user_arn != "" ? [1] : []
    content {
      name     = "UserDefinedRuleGroup"
      priority = 80

      override_action {
        none {}
      }

      statement {
        rule_group_reference_statement {
          arn = data.aws_wafv2_rule_group.user_provided[0].arn
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = "UserDefinedRuleGroup"
        sampled_requests_enabled   = true
      }
    }
  }

  # SQL Injection Rule Set
  dynamic "rule" {
    for_each = var.aws_waf_rule_sqli ? [1] : []
    content {
      name     = "AWSManagedRulesSQLiRuleSet"
      priority = 85

      override_action {
        none {}
      }

      statement {
        managed_rule_group_statement {
          name        = "AWSManagedRulesSQLiRuleSet"
          vendor_name = "AWS"
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = "AWSManagedRulesSQLiRuleSetMetric"
        sampled_requests_enabled   = true
      }
    }
  }

  # Linux Rule Set
  dynamic "rule" {
    for_each = var.aws_waf_rule_linux ? [1] : []
    content {
      name     = "AWSManagedRulesLinuxRuleSet"
      priority = 90

      override_action {
        none {}
      }

      statement {
        managed_rule_group_statement {
          name        = "AWSManagedRulesLinuxRuleSet"
          vendor_name = "AWS"
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = "AWSManagedRulesLinuxRuleSetMetric"
        sampled_requests_enabled   = true
      }
    }
  }

  # Unix Rule Set
  dynamic "rule" {
    for_each = var.aws_waf_rule_unix ? [1] : []
    content {
      name     = "AWSManagedRulesUnixRuleSet"
      priority = 95

      override_action {
        none {}
      }

      statement {
        managed_rule_group_statement {
          name        = "AWSManagedRulesUnixRuleSet"
          vendor_name = "AWS"
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = "AWSManagedRulesUnixRuleSetMetric"
        sampled_requests_enabled   = true
      }
    }
  }

  # Admin Protection Rule Set
  dynamic "rule" {
    for_each = var.aws_waf_rule_admin_protection ? [1] : []
    content {
      name     = "AWSManagedRulesAdminProtectionRuleSet"
      priority = 100

      override_action {
        none {}
      }

      statement {
        managed_rule_group_statement {
          name        = "AWSManagedRulesAdminProtectionRuleSet"
          vendor_name = "AWS"
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = "AWSManagedRulesAdminProtectionRuleSetMetric"
        sampled_requests_enabled   = true
      }
    }
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

# Add WAF outputs
output "waf_web_acl_arn" {
  value = var.aws_waf_enable ? aws_wafv2_web_acl.waf[0].arn : null
}

output "waf_web_acl_id" {
  value = var.aws_waf_enable ? aws_wafv2_web_acl.waf[0].id : null
}

# Read rule group by name
data "aws_wafv2_rule_group" "example" {
  count = var.aws_waf_rule_user_arn != "" ? [1] : []
  name  = "var.aws_waf_rule_user_arn"
  scope = "REGIONAL"
}

arn:aws:wafv2:us-east-1:755521597925:regional/rulegroup/some/351a2738-39ae-4d00-a864-599d6b3dc225