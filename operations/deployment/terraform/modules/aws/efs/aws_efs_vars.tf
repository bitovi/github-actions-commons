variable "aws_efs_create" {}
variable "aws_efs_fs_id" {}
variable "aws_efs_create_mount_target" {}
variable "aws_efs_create_ha" {}

variable "aws_efs_vol_encrypted" {}
variable "aws_efs_kms_key_id" {}
variable "aws_efs_performance_mode" {}
variable "aws_efs_throughput_mode" {}
variable "aws_efs_throughput_speed" {}

variable "aws_efs_security_group_name" {}
variable "aws_efs_allowed_security_groups" {}
variable "aws_efs_ingress_allow_all" {}

variable "aws_efs_create_replica" {}
variable "aws_efs_replication_destination" {}
variable "aws_efs_enable_backup_policy" {}
variable "aws_efs_transition_to_inactive" {}

# VPC inputs
variable "aws_selected_vpc_id" {}
variable "aws_selected_subnet_id" {}
# Others
variable "aws_resource_identifier" {}
