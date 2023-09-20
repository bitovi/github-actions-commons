module "aws_ecr" {
  source = "../modules/aws/ecr"
  # ECR
  aws_ecr_repo_type                         = var.aws_ecr_repo_type
  aws_ecr_repo_name                         = var.aws_ecr_repo_name
  aws_ecr_repo_mutable                      = var.aws_ecr_repo_mutable
  aws_ecr_repo_encryption_type              = var.aws_ecr_repo_encryption_type
  aws_ecr_repo_encryption_key_arn           = var.aws_ecr_repo_encryption_key_arn
  aws_ecr_repo_force_destroy                = var.aws_ecr_repo_force_destroy
  aws_ecr_repo_image_scan                   = var.aws_ecr_repo_image_scan
  aws_ecr_registry_scan_rule                = var.aws_ecr_registry_scan_rule
  aws_ecr_registry_pull_through_cache_rules = var.aws_ecr_registry_pull_through_cache_rules
  aws_ecr_registry_scan_config              = var.aws_ecr_registry_scan_config
  aws_ecr_registry_replication_rules_input  = var.aws_ecr_registry_replication_rules_input
  aws_ecr_repo_policy_attach                = var.aws_ecr_repo_policy_attach
  aws_ecr_repo_policy_create                = var.aws_ecr_repo_policy_create
  aws_ecr_repo_policy_input                 = var.aws_ecr_repo_policy_input
  aws_ecr_repo_read_arn                     = var.aws_ecr_repo_read_arn
  aws_ecr_repo_write_arn                    = var.aws_ecr_repo_write_arn
  aws_ecr_repo_read_arn_lambda              = var.aws_ecr_repo_read_arn_lambda
  aws_ecr_lifecycle_policy_input            = var.aws_ecr_lifecycle_policy_input
  aws_ecr_public_repo_catalog               = var.aws_ecr_public_repo_catalog
  aws_ecr_registry_policy_input             = var.aws_ecr_registry_policy_input
  # Others
  aws_resource_identifier                   = var.aws_resource_identifier

  providers = {
    aws = aws.ecr
  }
}

locals {
  aws_tags = {
    OperationsRepo            = "bitovi/github-actions-commons/operations/${var.ops_repo_environment}"
    AWSResourceIdentifier     = "${var.aws_resource_identifier}"
    GitHubOrgName             = "${var.app_org_name}"
    GitHubRepoName            = "${var.app_repo_name}"
    GitHubBranchName          = "${var.app_branch_name}"
    GitHubAction              = "bitovi/github-actions-commons"
    OperationsRepoEnvironment = "${var.ops_repo_environment}"
    Created_with              = "Bitovi-BitOps"
  }
  default_tags = merge(local.aws_tags, jsondecode(var.aws_additional_tags))
  # Module tagging
  ecr_tags    = merge(local.default_tags,jsondecode(var.aws_ecr_additional_tags))
}

output "ecr_repository_arn" {
  description = "Full ARN of the repository"
  value       = try(module.aws_ecr.repository_arn,null)
}

output "ecr_repository_registry_id" {
  description = "The registry ID where the repository was created"
  value       = try(module.aws_ecr.repository_registry_id,null)
}

output "ecr_repository_url" {
  description = "The URL of the repository"
  value       = try(module.aws_ecr.repository_url,null)
}