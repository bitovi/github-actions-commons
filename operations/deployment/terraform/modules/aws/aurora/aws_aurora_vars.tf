
variable "aws_aurora_engine" {}
variable "aws_aurora_engine_version" {}
variable "aws_aurora_database_group_family" {}
variable "aws_aurora_instance_class" {}
variable "aws_aurora_security_group_name" {}
variable "aws_aurora_subnets" {}
variable "aws_aurora_cluster_name" {}
variable "aws_aurora_database_name" {}
variable "aws_aurora_database_port" {}
variable "aws_aurora_restore_snapshot" {}
variable "aws_aurora_snapshot_name" {}
variable "aws_aurora_snapshot_overwrite" {}
variable "aws_aurora_database_protection" {}
variable "aws_aurora_database_final_snapshot" {}
variable "aws_subnets_vpc_subnets_ids" {}
variable "aws_resource_identifier" {}
variable "aws_resource_identifier_supershort" {}
variable "aws_allowed_sg_id" {}
variable "aws_selected_vpc_id" {}
variable "aws_region_current_name" {}
variable "default_tags" {
    type = map
    default = {}
}