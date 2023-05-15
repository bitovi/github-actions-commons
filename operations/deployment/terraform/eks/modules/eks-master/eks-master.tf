resource "aws_eks_cluster" "main" {
  name     = var.cluster_name
  role_arn = var.role_arn

  vpc_config {
    security_group_ids      = var.security_group_ids
    subnet_ids              = var.subnet_ids
    endpoint_private_access = var.endpoint_private_access
    endpoint_public_access  = var.endpoint_public_access
  }

  depends_on = [var.eks_depends_on]
  version    = var.k8s_master_version
  enabled_cluster_log_types = var.enabled_cluster_log_types

  tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
  }

}

data "aws_eks_cluster" "eks-cluster" {
  name = aws_eks_cluster.main.id
}

data "aws_eks_cluster_auth" "cluster_auth" {
  name = aws_eks_cluster.main.id
}

provider "kubernetes" {
  host                   = aws_eks_cluster.main.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.main.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.main.token
  #load_config_file       = false
}

output "eks_master_id" {
  description = "The name of the cluster"
  value       = aws_eks_cluster.main.id
}

output "eks_master_arn" {
  description = "The Amazon Resource Name (ARN) of the cluster"
  value       = aws_eks_cluster.main.arn
}

output "eks_master_endpoint" {
  description = "The endpoint for your Kubernetes API server"
  value       = aws_eks_cluster.main.endpoint
}

output "cluster_certificate_authority_data" {
  value       = aws_eks_cluster.main.certificate_authority.0.data
}

output "cluster_auth_token" {
  value       = data.aws_eks_cluster_auth.cluster_auth.token
  sensitive = true
}

output "cluster_version" {
  value       = aws_eks_cluster.main.version
}