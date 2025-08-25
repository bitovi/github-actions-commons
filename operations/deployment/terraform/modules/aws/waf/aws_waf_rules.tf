# Local variables definition
locals {
  aws_waf_rule_geo_block_countries = var.aws_waf_rule_geo_block_countries != "" ? [
    for n in split(",", var.aws_waf_rule_geo_block_countries) : trim(n)
  ] : []

  aws_waf_rule_geo_allow_only_countries = var.aws_waf_rule_geo_allow_only_countries != "" ? [
    for n in split(",", var.aws_waf_rule_geo_allow_only_countries) : trim(n)
  ] : []
}

# Custom Rate-Limiting Rule Group
resource "aws_wafv2_web_acl_rule_group_association" "rate_limit_rule_association" {
  count       = var.aws_waf_rule_rate_limit != "" ? 1: 0
  rule_name   = "rate-limit-rule"
  priority    = 10
  web_acl_arn = aws_wafv2_web_acl.waf[0].arn

  rule_group_reference {
    arn = aws_wafv2_rule_group.rate_limit_rule_group[0].arn
  }
}

resource "aws_wafv2_rule_group" "rate_limit_rule_group" {
  count    = var.aws_waf_rule_rate_limit != "" ? 1: 0
  name     = "${var.aws_resource_identifier}-RateLimitRule"
  scope    = "REGIONAL"
  capacity = 50

  # Rate limiting rule
  rule {
    name     = "RateLimitRule"
    priority = 1

    statement {
      rate_based_statement {
        limit              = tonumber(var.aws_waf_rule_rate_limit)
        aggregate_key_type = "IP"
      }
    }
    action {
      block {}
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "RateLimitRule"
      sampled_requests_enabled   = true
    }
  }
  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "RateLimitRule-group"
    sampled_requests_enabled   = true
  }
}

# Managed rule association set 
# Common Rule Set
resource "aws_wafv2_web_acl_rule_group_association" "managed_common" {
  count       = var.aws_waf_rule_managed_rules ? 1 : 0
  rule_name   = "AWSManagedRulesCommonRuleSet"
  priority    = 20
  web_acl_arn = aws_wafv2_web_acl.waf[0].arn

  managed_rule_group {
    name        = "AWSManagedRulesCommonRuleSet"
    vendor_name = "AWS"
  }
}


# Known Bad Inputs Rule Set
resource "aws_wafv2_web_acl_rule_group_association" "managed_bad_inputs" {
  count       = var.aws_waf_rule_managed_bad_inputs ? 1 : 0
  rule_name   = "AWSManagedRulesKnownBadInputsRuleSet"
  priority    = 30
  web_acl_arn = aws_wafv2_web_acl.waf[0].arn

  managed_rule_group {
    name        = "AWSManagedRulesKnownBadInputsRuleSet"
    vendor_name = "AWS"
  }
}

# IP Reputation Rule Set
resource "aws_wafv2_web_acl_rule_group_association" "managed_ip_reputation" {
  count       = var.aws_waf_rule_ip_reputation ? 1 : 0
  rule_name   = "AWSManagedRulesAmazonIpReputationList"
  priority    = 40
  web_acl_arn = aws_wafv2_web_acl.waf[0].arn

  managed_rule_group {
    name        = "AWSManagedRulesAmazonIpReputationList"
    vendor_name = "AWS"
  }
}

# Anonymous IPs
resource "aws_wafv2_web_acl_rule_group_association" "managed_anonymous_ip" {
  count       = var.aws_waf_rule_anonymous_ip ? 1 : 0
  rule_name   = "AWSManagedRulesAnonymousIpList"
  priority    = 50
  web_acl_arn = aws_wafv2_web_acl.waf[0].arn

  managed_rule_group {
    name        = "AWSManagedRulesAnonymousIpList"
    vendor_name = "AWS"
  }
}

# Optional Bot Control (extra cost)
resource "aws_wafv2_web_acl_rule_group_association" "managed_bot_control" {
  count       = var.aws_waf_rule_bot_control ? 1 : 0
  rule_name   = "AWSManagedRulesBotControlRuleSet"
  priority    = 60
  web_acl_arn = aws_wafv2_web_acl.waf[0].arn

  managed_rule_group {
    name        = "AWSManagedRulesBotControlRuleSet"
    vendor_name = "AWS"
  }
}

#################################
# Geo-Blocking Custom Rule
#################################
resource "aws_wafv2_web_acl_rule_group_association" "geo_block" {
  count       = length(local.aws_waf_rule_geo_block_countries) > 0 ? 1 : 0
  rule_name   = "geo-blocking"
  priority    = 70
  web_acl_arn = aws_wafv2_web_acl.waf[0].arn

  rule {
    name     = "GeoBlockRule"
    priority = 1
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

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "GeoBlockGroup"
    sampled_requests_enabled   = true
  }
}
#################################
# Geo-Allow-Only Custom Rule
#################################
resource "aws_wafv2_web_acl_rule_group_association" "geo_allow_only" {
  count       = length(local.aws_waf_rule_geo_allow_only_countries) > 0 ? 1 : 0
  rule_name   = "geo-allow-only"
  priority    = 75
  web_acl_arn = aws_wafv2_web_acl.waf[0].arn

  rule {
    name     = "GeoAllowOnlyRule"
    priority = 1
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

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "GeoAllowOnlyGroup"
    sampled_requests_enabled   = true
  }
}


#################################
# User-Defined External Rule Group (Content of it ignored by Terraform)
#################################
resource "aws_wafv2_web_acl_rule_group_association" "user_defined" {
  count       = var.aws_waf_rule_user_arn != "" ? 1 : 0
  rule_name   = "user-defined-rule"
  priority    = 80
  web_acl_arn = aws_wafv2_web_acl.waf[0].arn

  rule_group_reference {
    arn = var.aws_waf_rule_user_arn
  }
}

## Extra set 
# SQL Injection Rule Set
resource "aws_wafv2_web_acl_rule_group_association" "managed_sqli" {
  count       = var.aws_waf_rule_sqli ? 1 : 0
  rule_name   = "AWSManagedRulesSQLiRuleSet"
  priority    = 85
  web_acl_arn = aws_wafv2_web_acl.waf[0].arn

  managed_rule_group {
    name        = "AWSManagedRulesSQLiRuleSet"
    vendor_name = "AWS"
  }
}

# Linux Rule Set
resource "aws_wafv2_web_acl_rule_group_association" "managed_linux" {
  count       = var.aws_waf_rule_linux ? 1 : 0
  rule_name   = "AWSManagedRulesLinuxRuleSet"
  priority    = 90
  web_acl_arn = aws_wafv2_web_acl.waf[0].arn

  managed_rule_group {
    name        = "AWSManagedRulesLinuxRuleSet"
    vendor_name = "AWS"
  }
}

# Unix Rule Set
resource "aws_wafv2_web_acl_rule_group_association" "managed_unix" {
  count       = var.aws_waf_rule_unix ? 1 : 0
  rule_name   = "AWSManagedRulesUnixRuleSet"
  priority    = 95
  web_acl_arn = aws_wafv2_web_acl.waf[0].arn

  managed_rule_group {
    name        = "AWSManagedRulesUnixRuleSet"
    vendor_name = "AWS"
  }
}

# Admin Protection Rule Set
resource "aws_wafv2_web_acl_rule_group_association" "managed_admin_protection" {
  count       = var.aws_waf_rule_admin_protection ? 1 : 0
  rule_name   = "AWSManagedRulesAdminProtectionRuleSet"
  priority    = 100
  web_acl_arn = aws_wafv2_web_acl.waf[0].arn

  managed_rule_group {
    name        = "AWSManagedRulesAdminProtectionRuleSet"
    vendor_name = "AWS"
  }
}
