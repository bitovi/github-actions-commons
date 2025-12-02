
variable "aws_alb_security_group_name" {}
variable "aws_alb_app_port" {}
variable "aws_alb_app_protocol" {}
variable "aws_alb_listen_port" {}
variable "aws_alb_listen_protocol" {}
variable "aws_alb_healthcheck_path" {}
variable "aws_alb_healthcheck_protocol" {}
variable "aws_alb_ssl_policy" {}

# Logging
variable "aws_alb_access_log_enabled" {}
variable "aws_alb_access_log_bucket_name" {}
variable "aws_alb_access_log_expire" {}

#variable "aws_instance_server_az" {} #TBD
variable "aws_vpc_selected_id" {}
variable "aws_vpc_subnet_selected" {}
variable "aws_instance_server_id" {}
variable "aws_certificates_selected_arn" {}
variable "aws_alb_target_sg_id" {}

variable "aws_resource_identifier" {}
variable "aws_resource_identifier_supershort" {}