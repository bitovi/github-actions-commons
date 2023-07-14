
variable "aws_postgres_engine" {}
variable "aws_postgres_engine_version" {}
variable "aws_postgres_database_group_family" {}
variable "aws_postgres_instance_class" {}
variable "aws_postgres_security_group_name" {}
variable "aws_postgres_subnets" {}
variable "aws_postgres_cluster_name" {}
variable "aws_postgres_database_name" {}
variable "aws_postgres_database_port" {}
variable "aws_postgres_restore_snapshot" {}
variable "aws_postgres_snapshot_name" {}
variable "aws_postgres_snapshot_overwrite" {}
variable "aws_postgres_database_protection" {}
variable "aws_postgres_database_final_snapshot" {}
variable "aws_subnets_vpc_subnets_ids" {}
variable "aws_resource_identifier" {}
variable "aws_resource_identifier_supershort" {}
variable "aws_vpc_default_id" {}
variable "aws_region_current_name" {}
variable "common_tags" {
    type = map
    default = {}
}

