
variable "aws_elb_security_group_name" {}
variable "aws_elb_app_port" {}
variable "aws_elb_app_protocol" {}
variable "aws_elb_listen_port" {}
variable "aws_elb_listen_protocol" {}
variable "aws_elb_healthcheck" {}
variable "aws_elb_access_log_bucket_name" {}
variable "aws_elb_access_log_expire" {}

variable "aws_instance_server_az" {}
variable "aws_vpc_selected_id" {}
variable "aws_vpc_subnet_selected" {}
variable "aws_instance_server_id" {}
variable "aws_certificates_selected_arn" {}
variable "aws_elb_target_sg_id" {}

variable "aws_resource_identifier" {}
variable "aws_resource_identifier_supershort" {}