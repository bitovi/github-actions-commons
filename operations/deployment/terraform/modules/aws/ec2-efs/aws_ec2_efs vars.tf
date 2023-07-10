# EFS
variable "aws_efs_create" {}
variable "aws_efs_create_ha" {}
variable "aws_efs_mount_id" {}
variable "aws_efs_mount_security_group_id" {}
variable "aws_efs_zone_mapping" {}
variable "aws_efs_ec2_mount_point" {}
# EC2
variable "aws_ec2_instance_type" {}
# Docker
variable "docker_efs_mount_target" {}
# Data inputs
variable "aws_region_current_name" {}
variable "aws_security_group_default_id" {}
variable "aws_security_group_ec2_sg_name" {}
variable "aws_security_group_ec2_sg_id" {}
# Others
variable "aws_resource_identifier" {}
# Not exposed
variable "availability_zone" {}
variable "app_install_root" {}
variable "app_repo_name" {}

variable "common_tags" {
    type = map
    default = {}
}