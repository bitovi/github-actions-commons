variable "aws_resource_identifier" {}
variable "aws_efs_replication_destination" {}
variable "aws_efs_transition_to_inactive" {}
variable "aws_efs_security_group_name" {}
variable "aws_efs_enable_backup_policy" {}
variable "aws_efs_create_replica" {}

variable "aws_region_current_name" {}
variable "aws_vpc_default_id" {}

variable "common_tags" {
    type = map
    default = {}
}