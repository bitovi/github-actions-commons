# EFS
variable "aws_efs_create" {}
variable "aws_efs_create_ha" {}
variable "aws_efs_mount_id" {}
variable "aws_efs_zone_mapping" {}
variable "aws_efs_ec2_mount_point" {}
# Other
variable "ha_zone_mapping" {}
variable "ec2_zone_mapping" {}
# Docker
variable "docker_efs_mount_target" {}
# Data inputs
variable "aws_region_current_name" {}
variable "aws_security_group_efs_id" {}
variable "aws_efs_fs_id" {}
# Others
variable "common_tags" {
    type = map
    default = {}
}
# Not exposed
variable "app_install_root" {}
variable "app_repo_name" {}