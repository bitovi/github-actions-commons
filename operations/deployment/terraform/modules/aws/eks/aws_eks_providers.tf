terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
        source  = "hashicorp/kubernetes"
        version = "~> 2.0"
    }
  }
}

#provider "kubernetes" {
#  host                   = data.aws_eks_cluster.eks_cluster.endpoint
#  cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks_cluster.certificate_authority.0.data)
#  token                  = data.aws_eks_cluster_auth.cluster_auth.token
#}