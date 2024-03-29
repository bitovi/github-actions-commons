# ECR
variable "aws_ecr_repo_type" {}
variable "aws_ecr_repo_name" {}
variable "aws_ecr_repo_mutable" {}
variable "aws_ecr_repo_encryption_type" {}
variable "aws_ecr_repo_encryption_key_arn" {}
variable "aws_ecr_repo_force_destroy" {}
variable "aws_ecr_repo_image_scan" {}
variable "aws_ecr_registry_scan_rule" {}
variable "aws_ecr_registry_pull_through_cache_rules" {}
variable "aws_ecr_registry_scan_config" {}
variable "aws_ecr_registry_replication_rules_input" {}
variable "aws_ecr_repo_policy_attach" {}
variable "aws_ecr_repo_policy_create" {}
variable "aws_ecr_repo_policy_input" {}
variable "aws_ecr_repo_read_arn" {}
variable "aws_ecr_repo_write_arn" {}
variable "aws_ecr_repo_read_arn_lambda" {}
variable "aws_ecr_lifecycle_policy_input" {}
variable "aws_ecr_public_repo_catalog" {}
variable "aws_ecr_registry_policy_input" {}
variable "aws_resource_identifier" {}