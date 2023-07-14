#EFS
variable "aws_efs_replication_destination" {}
variable "aws_efs_transition_to_inactive" {}
variable "aws_efs_security_group_name" {}
variable "aws_efs_enable_backup_policy" {}
variable "aws_efs_create_replica" {}
# EC2
variable "aws_ec2_instance_create" {}
# VPC inputs
variable "aws_vpc_id" {}
variable "aws_vpc_cidr_block_whitelist" {}
variable "aws_region_current_name" {}
# Others
variable "aws_resource_identifier" {}
variable "common_tags" {
    type = map
    default = {}
}