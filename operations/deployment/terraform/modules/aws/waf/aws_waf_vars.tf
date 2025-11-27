## WAF
variable "aws_waf_enable" {}
variable "aws_lb_resource_arn" {}
variable "aws_waf_logging_enable" {}
variable "aws_waf_log_retention_days" {}
variable "aws_resource_identifier" {}

variable "aws_waf_rule_rate_limit" {}               # - Rate limit (requests per 5 minutes)
variable "aws_waf_rule_managed_rules" {}            # - Managed rule groups
variable "aws_waf_rule_managed_bad_inputs" {}       # - Known bad inputs rule
variable "aws_waf_rule_ip_reputation" {}            # - IP reputation rule
variable "aws_waf_rule_anonymous_ip" {}             # - Anonymous IPs rule
variable "aws_waf_rule_bot_control" {}              # - Bot control rule
variable "aws_waf_rule_geo_block_countries" {}      # - List of countries to block
variable "aws_waf_rule_geo_allow_only_countries" {} # - List of countries to allow only
variable "aws_waf_rule_user_arn" {}                 # - ARN of the user-defined rule group
variable "aws_waf_rule_sqli" {}                     # - SQL injection rule
variable "aws_waf_rule_linux" {}                    # - Linux rule
variable "aws_waf_rule_unix" {}                     # - Unix rule
variable "aws_waf_rule_admin_protection" {}         # - Admin protection rule