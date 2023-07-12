# EFS
variable "aws_efs_create" {}
variable "aws_efs_create_ha" {}
variable "aws_efs_mount_id" {}
variable "aws_efs_zone_mapping" {}
variable "aws_efs_ec2_mount_point" {}
variable "ha_zone_mapping" {}
variable "ec2_zone_mapping" {}
# EC2
variable "aws_elb_target_sg_id" {}
# Docker
variable "docker_efs_mount_target" {}
# Data inputs
variable "aws_region_current_name" {} 

# Others
variable "aws_resource_identifier" {}
# Not exposed
variable "app_install_root" {}
variable "app_repo_name" {}

variable "common_tags" {
    type = map
    default = {}
}