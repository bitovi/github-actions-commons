module "eks_vpc" {
  source             = "terraform-aws-modules/vpc/aws"
  name               = var.aws_eks_vpc_name != "" ? var.aws_eks_vpc_name : "VPC for ${var.aws_eks_cluster_name} - EKS"
  cidr               = var.aws_eks_cidr_block
  azs                = local.aws_eks_availability_zones
  private_subnets    = local.aws_eks_private_subnets
  public_subnets     = local.aws_eks_public_subnets
  enable_nat_gateway = true
  enable_dns_hostnames= true

  tags = {
    // This is needed for k8s to use VPC resources
    "kubernetes.io/cluster/${var.aws_eks_cluster_name}" = "shared"
    "environment"                                       = var.aws_eks_environment
  }

  // Tags required by k8s to launch services on the right subnets
  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
  }
  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1 
  }
}

locals {
  aws_eks_availability_zones = var.aws_eks_availability_zones != "" ? [for n in split(",", var.aws_eks_availability_zones) : (n)] : []
  aws_eks_private_subnets    = var.aws_eks_private_subnets != "" ? [for n in split(",", var.aws_eks_private_subnets) : (n)] : []
  aws_eks_public_subnets     = var.aws_eks_public_subnets != "" ? [for n in split(",", var.aws_eks_public_subnets) : (n)] : []
}