variable "aws_redis_user" {}
variable "aws_redis_user_access_string" {}
variable "aws_redis_user_group_name" {}

variable "aws_redis_security_group_name" {}
variable "aws_redis_ingress_allow_all" {}
variable "aws_redis_allowed_security_groups" {}
variable "aws_redis_subnets" {}
variable "aws_redis_port" {}
variable "aws_redis_at_rest_encryption" {}
variable "aws_redis_in_transit_encryption" {}

variable "aws_redis_replication_group_id" {}
variable "aws_redis_node_type" {}
variable "aws_redis_num_cache_clusters" {}
variable "aws_redis_parameter_group_name" {}
variable "aws_redis_num_node_groups" {}
variable "aws_redis_replicas_per_node_group" {}
variable "aws_redis_multi_az_enabled" {}
variable "aws_redis_automatic_failover" {}
variable "aws_redis_apply_immediately" {}
variable "aws_redis_auto_minor_upgrade" {}
variable "aws_redis_maintenance_window" {}
variable "aws_redis_snapshot_window" {}
variable "aws_redis_final_snapshot" {}
variable "aws_redis_snapshot_restore_name" {}

variable "aws_redis_cloudwatch_enabled" {}
variable "aws_redis_cloudwatch_lg_name" {}
variable "aws_redis_cloudwatch_log_format" {}
variable "aws_redis_cloudwatch_log_type" {}
variable "aws_redis_cloudwatch_retention_days" {}
variable "aws_redis_single_line_url_secret" {}

variable "aws_selected_vpc_id" {} 
variable "aws_selected_subnets" {}
variable "aws_resource_identifier" {}
variable "aws_resource_identifier_supershort" {}