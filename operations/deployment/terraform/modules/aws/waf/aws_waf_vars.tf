## WAF
variable "aws_waf_enable" {}
variable "aws_lb_resource_arn" {}
variable "aws_waf_logging_enable" {}
variable "aws_waf_log_retention_days" {}
variable "aws_resource_identifier" {}

variable "aws_waf_rule_rate_limit" {}                        # - Rate limit (requests per 5 minutes)
variable "aws_waf_rule_rate_limit_priority" {}               # - Priority for rate limit rule
variable "aws_waf_rule_managed_rules" {}                     # - Managed rule groups
variable "aws_waf_rule_managed_rules_priority" {}            # - Priority for managed rules
variable "aws_waf_rule_managed_bad_inputs" {}                # - Known bad inputs rule
variable "aws_waf_rule_managed_bad_inputs_priority" {}       # - Priority for known bad inputs rule
variable "aws_waf_rule_ip_reputation" {}                     # - IP reputation rule
variable "aws_waf_rule_ip_reputation_priority" {}            # - Priority for IP reputation rule
variable "aws_waf_rule_anonymous_ip" {}                      # - Anonymous IPs rule
variable "aws_waf_rule_anonymous_ip_priority" {}             # - Priority for anonymous IPs rule
variable "aws_waf_rule_bot_control" {}                       # - Bot control rule
variable "aws_waf_rule_bot_control_priority" {}              # - Priority for bot control rule
variable "aws_waf_rule_geo_block_countries" {}               # - List of countries to block
variable "aws_waf_rule_geo_block_countries_priority" {}      # - Priority for geo block rule
variable "aws_waf_rule_geo_allow_only_countries" {}          # - List of countries to allow only
variable "aws_waf_rule_geo_allow_only_countries_priority" {} # - Priority for geo allow only rule
variable "aws_waf_rule_user_arn" {}                          # - ARN of the user-defined rule group
variable "aws_waf_rule_user_arn_priority" {}                 # - Priority for user-defined rule group
variable "aws_waf_rule_sqli" {}                              # - SQL injection rule
variable "aws_waf_rule_sqli_priority" {}                     # - Priority for SQL injection rule
variable "aws_waf_rule_linux" {}                             # - Linux rule
variable "aws_waf_rule_linux_priority" {}                    # - Priority for Linux rule
variable "aws_waf_rule_unix" {}                              # - Unix rule
variable "aws_waf_rule_unix_priority" {}                     # - Priority for Unix rule
variable "aws_waf_rule_admin_protection" {}                  # - Admin protection rule
variable "aws_waf_rule_admin_protection_priority" {}         # - Priority for admin protection rule