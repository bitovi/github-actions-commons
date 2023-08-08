variable "aws_efs_create" {}
variable "aws_efs_create_ha" {}
variable "aws_efs_fs_id" {}
variable "aws_efs_vpc_id" {}
variable "aws_efs_subnet_ids" {}
variable "aws_efs_security_group_name" {}
variable "aws_efs_create_replica" {}
variable "aws_efs_replication_destination" {}
variable "aws_efs_enable_backup_policy" {}
variable "aws_efs_transition_to_inactive" {}
# VPC inputs
variable "aws_selected_vpc_id" {}
variable "aws_selected_subnet_id" {}
variable "aws_selected_az" {}
variable "aws_selected_az_list" {}
# Others
variable "aws_resource_identifier" {}
variable "common_tags" {
    type = map
    default = {}
}