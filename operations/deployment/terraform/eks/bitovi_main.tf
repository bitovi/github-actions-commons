module "eks" {
  source = "../modules/aws/eks"
  aws_eks_region                     = var.aws_eks_region
  aws_eks_security_group_name_master = var.aws_eks_security_group_name_master
  aws_eks_security_group_name_worker = var.aws_eks_security_group_name_worker
  aws_eks_environment                = var.aws_eks_environment
  aws_eks_stackname                  = var.aws_eks_stackname
  aws_eks_cidr_block                 = var.aws_eks_cidr_block
  aws_eks_workstation_cidr           = var.aws_eks_workstation_cidr
  aws_eks_availability_zones         = var.aws_eks_availability_zones
  aws_eks_private_subnets            = var.aws_eks_private_subnets
  aws_eks_public_subnets             = var.aws_eks_public_subnets
  aws_eks_cluster_name               = var.aws_eks_cluster_name
  aws_eks_cluster_log_types          = var.aws_eks_cluster_log_types
  aws_eks_cluster_version            = var.aws_eks_cluster_version
  aws_eks_instance_type              = var.aws_eks_instance_type
  aws_eks_instance_ami_id            = var.aws_eks_instance_ami_id
  aws_eks_instance_user_data_file    = var.aws_eks_instance_user_data_file
  aws_eks_ec2_key_pair               = var.aws_eks_ec2_key_pair
  aws_eks_store_keypair_sm           = var.aws_eks_store_keypair_sm
  aws_eks_desired_capacity           = var.aws_eks_desired_capacity
  aws_eks_max_size                   = var.aws_eks_max_size
  aws_eks_min_size                   = var.aws_eks_min_size
  # Hidden
  aws_eks_vpc_name = var.aws_eks_vpc_name
  # Others
  aws_resource_identifier = var.aws_resource_identifier
  common_tags             = merge(local.default_tags,jsondecode(var.aws_eks_additional_tags))
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
  default_tags = merge(local.aws_tags, var.aws_additional_tags)
}