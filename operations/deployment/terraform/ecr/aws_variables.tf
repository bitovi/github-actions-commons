# AWS Specific

variable "aws_resource_identifier" {
  type        = string
  description = "Identifier to use for AWS resources (defaults to GITHUB_ORG-GITHUB_REPO-GITHUB_BRANCH)"
}

variable "aws_resource_identifier_supershort" {
  type        = string
  description = "Identifier to use for AWS resources (defaults to GITHUB_ORG-GITHUB_REPO-GITHUB_BRANCH) shortened to 30 chars"
}

variable "aws_additional_tags" {
  type        = string
  description = "A list of strings that will be added to created resources"
  default     = "{}"
}

# ECR
variable "aws_ecr_repo_create" { 
  description = "Determines whether a repository will be created"
  type        = bool
  default     = false
}

variable "aws_ecr_repo_type" { 
  description = "The type of repository to create. Either `public` or `private`"
  type        = string
  default     = "private"
}

variable "aws_ecr_repo_name" {
  description = "The name of the repository. Will use the default resource-identifier"
  type        = string
  default     = ""
}

variable "aws_ecr_repo_mutable" {
  description = "The tag mutability setting for the repository. Set this to true if `MUTABLE`. Defaults to false, so `IMMUTABLE`"
  type        = bool
  default     = false
}

variable "aws_ecr_repo_encryption_type" {
  description = "The encryption type for the repository. Must be one of: `KMS` or `AES256`. Defaults to `AES256`"
  type        = string
  default     = "AES256"
}

variable "aws_ecr_repo_encryption_key_arn" {
  description = "The ARN of the KMS key to use when encryption_type is `KMS`. If not specified, uses the default AWS managed key for ECR"
  type        = string
  default     = null
}

variable "aws_ecr_repo_force_destroy" {
  description = "If `true`, will delete the repository even if it contains images. Defaults to `false`"
  type        = bool
  default     = null
}

variable "aws_ecr_repo_image_scan" {
  description = "Indicates whether images are scanned after being pushed to the repository (`true`) or not scanned (`false`)"
  type        = bool
  default     = true
}

variable "aws_ecr_registry_scan_rule" {
  description = "One or multiple blocks specifying scanning rules to determine which repository filters are used and at what frequency scanning will occur"
  type        = any
  default     = []
}

variable "aws_ecr_registry_pull_through_cache_rules" {
  description = "List of pull through cache rules to create"
  type        = map(map(string))
  default     = {}
}

variable "aws_ecr_registry_scan_config" {
  description = "the scanning type to set for the registry. Can be either `ENHANCED` or `BASIC`. Defaults to null."
  type        = string
  default     = ""
}

variable "aws_ecr_registry_replication_rules_input" {
  description = "The replication rules for a replication configuration. A maximum of 10 are allowed"
  type        = any
  default     = []
}

# ECR Policies

variable "aws_ecr_repo_policy_attach" {
  description = "Determines whether a repository policy will be attached to the repository"
  type        = bool
  default     = true
}

variable "aws_ecr_repo_policy_create" {
  description = "Determines whether a repository policy will be created. Defaults to true."
  type        = bool
  default     = true
}

variable "aws_ecr_repo_policy_input" {
  description = "The JSON policy to apply to the repository. If defined overrides the default policy"
  type        = string
  default     = ""
}

variable "aws_ecr_repo_read_arn" {
  description = "The ARNs of the IAM users/roles that have read access to the repository"
  type        = string
  default     = ""
}

variable "aws_ecr_repo_write_arn" {
  description = "The ARNs of the IAM users/roles that have read/write access to the repository"
  type        = string
  default     = ""
}

variable "aws_ecr_repo_read_arn_lambda" {
  description = "The ARNs of the Lambda service roles that have read access to the repository"
  type        = string
  default     = ""
}

variable "aws_ecr_lifecycle_policy_input" {
  description = "The policy document. This is a JSON formatted string. See more details about [Policy Parameters](http://docs.aws.amazon.com/AmazonECR/latest/userguide/LifecyclePolicies.html#lifecycle_policy_parameters) in the official AWS docs"
  type        = string
  default     = ""
}

variable "aws_ecr_public_repo_catalog" {
  description = "Catalog data configuration for the repository"
  type        = any
  default     = {}
}

variable "aws_ecr_registry_policy_input" { 
  description = "The policy document. This is a JSON formatted string"
  type        = string
  default     = ""
}

variable "aws_ecr_additional_tags" {
  type        = string
  description = "A list of strings that will be added to created resources"
  default     = "{}"
}


#### END OF ACTION VARIABLES INPUTS
#### The following are not being exposed directly to the end user

variable "app_repo_name" {
  type        = string
  description = "GitHub Repo Name"
}
variable "app_org_name" {
  type        = string
  description = "GitHub Org Name"
}
variable "app_branch_name" {
  type        = string
  description = "GitHub Branch Name"
}
variable "ops_repo_environment" {
  type        = string
  description = "Ops Repo Environment (i.e. directory name)"
}