variable "aws_resource_identifier" {}
variable "aws_efs_replication_destination" {}
variable "aws_efs_transition_to_inactive" {}
variable "aws_efs_security_group_name" {}
variable "aws_efs_enable_backup_policy" {}
variable "aws_efs_create_replica" {}

variable "aws_ec2_instance_create" {}

variable "aws_region_current_name" {}
variable "aws_vpc_default_id" {}

variable "common_tags" {
    type = map
    default = {}
}



variable "aws_efs_mount_security_group_id" {}
variable "aws_security_group_ec2_sg_id" {}

#variable "aws_ec2_instance_type" {}
#variable "aws_security_group_default_id" {}
#variable "aws_security_group_ec2_sg_name" {}
#variable "availability_zone" {}