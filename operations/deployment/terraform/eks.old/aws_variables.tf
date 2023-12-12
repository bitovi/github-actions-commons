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

# EKS
variable "aws_eks_create" {
  type        = bool
  description = "deploy a eks cluster"
  default     = false
}

variable "aws_eks_region" {
  description = "aws region name"
  type        = string
  default     = "us-east-1"
}

variable "aws_eks_security_group_name_master" {
  description = "aws aws_eks_security_group_name_master name"
  type        = string
  default     = ""
}

variable "aws_eks_security_group_name_worker" {
  description = "aws aws_eks_security_group_name_worker name"
  type        = string
  default     = ""
}

variable "aws_eks_vpc_name" {
  description = "aws eks vpc name"
  type        = string
  default     = ""
}

variable "aws_eks_environment" {
  description = "eks environment name"
  type        = string
  default     = "env"
}

variable "aws_eks_stackname" {
  description = "enter the eks stack name"
  type        = string
  default     = "eks-stack"
}

variable "aws_eks_cidr_block" {
  type        = string
  description = "Base CIDR block which is divided into subnet CIDR blocks (e.g. `10.0.0.0/16`)"
  default     = "10.0.0.0/16"
}

variable "aws_eks_workstation_cidr" {
  type        = string
  description = "your local workstation public IP"
  default     = ""
}

variable "aws_eks_availability_zones" {
  type        = string
  description = "List of Availability Zones (e.g. `['us-east-1a', 'us-east-1b', 'us-east-1c']`)"
  default     = "us-east-1a,us-east-1b"
}

variable "aws_eks_private_subnets" {
  type        = string
  description = "List of private subnets (e.g. `['10.0.1.0/24', '10.0.2.0/24']`)"
  default     = "10.0.1.0/24,10.0.2.0/24"
}

variable "aws_eks_public_subnets" {
  type        = string
  description = "List of public subnets (e.g. `['10.0.101.0/24', '10.0.102.0/24']`)"
  default     = "10.0.101.0/24,10.0.102.0/24"
}

variable "aws_eks_cluster_name" {
  description = "kubernetes cluster name"
  type        = string
  default     = ""
}

variable "aws_eks_cluster_log_types" {
  description = "enter the kubernetes version"
  type        = string
  default     = ""
}

variable "aws_eks_cluster_version" {
  description = "enter the kubernetes version"
  type        = number
  default     = "1.27"
}

variable "aws_eks_instance_type" {
  description = "enter the aws instance type"
  type        = string
  default     = "t3a.medium"
}

variable "aws_eks_instance_ami_id" {
  description = "AWS AMI ID"
  type        = string
  default     = ""
}

variable "aws_eks_instance_user_data_file" {
  description = "enter the aws instance user data file"
  type        = string
  default     = ""
}

variable "aws_eks_ec2_key_pair" {
  description = "Enter the existing ec2 key pair for worker nodes"
  type        = string
  default     = ""
}

variable "aws_eks_store_keypair_sm" {
  description = "y/n create sm entry for ec2 keypair"
  type        = bool
  default     = false
}

variable "aws_eks_desired_capacity" {
  description = "Enter the desired capacity for the worker nodes"
  type        = number
  default     = "2"
}

variable "aws_eks_max_size" {
  description = "Enter the max_size for the worker nodes"
  type        = number
  default     = "4"
}

variable "aws_eks_min_size" {
  description = "Enter the min_size for the worker nodes"
  type        = number
  default     = "2"
}

variable "aws_eks_additional_tags" {
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