# DB params
variable "aws_aurora_cluster_name" {}
variable "aws_aurora_engine" {}
variable "aws_aurora_engine_version" {}
variable "aws_aurora_engine_mode" {}
variable "aws_aurora_cluster_apply_immediately" {}
# Storage 
variable "aws_aurora_allocated_storage" {}
variable "aws_aurora_storage_encrypted" {}
variable "aws_aurora_kms_key_id" {}
variable "aws_aurora_storage_type" {}
variable "aws_aurora_storage_iops" {}
# DB Details
variable "aws_aurora_database_name" {}
variable "aws_aurora_master_username" {}
variable "aws_aurora_database_group_family" {}
variable "aws_aurora_iam_auth_enabled" {}
variable "aws_aurora_iam_roles" {}
# Net
variable "aws_aurora_cluster_db_instance_class" {}
variable "aws_aurora_security_group_name" {}
variable "aws_aurora_allowed_security_groups" {}
variable "aws_aurora_subnets" {}
variable "aws_aurora_database_port" {}
variable "aws_aurora_db_publicly_accessible" {}
# Backup & maint
variable "aws_aurora_cloudwatch_enable" {}
variable "aws_aurora_cloudwatch_log_type" {}
variable "aws_aurora_cloudwatch_retention_days" {}
variable "aws_aurora_backtrack_window" {}
variable "aws_aurora_backup_retention_period" {}
variable "aws_aurora_backup_window" {}
variable "aws_aurora_maintenance_window" {}
variable "aws_aurora_database_final_snapshot" {}
variable "aws_aurora_deletion_protection" {}
variable "aws_aurora_delete_auto_backups" {}
variable "aws_aurora_restore_snapshot_id" {}
variable "aws_aurora_restore_to_point_in_time" {}
variable "aws_aurora_snapshot_name" {}
variable "aws_aurora_snapshot_overwrite" {}
# DB Parameters
variable "aws_aurora_db_instances_count" {}
variable "aws_aurora_db_instance_class" {}
variable "aws_aurora_db_apply_immediately" {}
variable "aws_aurora_db_ca_cert_identifier" {}
variable "aws_aurora_db_maintenance_window" {}
# Incoming
variable "aws_selected_vpc_id" {}
variable "aws_subnets_vpc_subnets_ids" {}
variable "aws_resource_identifier" {}
variable "aws_resource_identifier_supershort" {}