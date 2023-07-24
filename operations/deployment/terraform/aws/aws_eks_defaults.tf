data "aws_eks_cluster" "eks_cluster" {
  name = try(module.eks[0].aws_eks_cluster_main_id,"")
}

data "aws_eks_cluster_auth" "cluster_auth" {
  name = try(module.eks[0].aws_eks_cluster_main_id,"")
}

provider "kubernetes" {
  host                   = try(data.aws_eks_cluster.eks_cluster.endpoint,"")
  cluster_ca_certificate = try(base64decode(data.aws_eks_cluster.eks_cluster.certificate_authority.0.data),"")
  token                  = try(data.aws_eks_cluster_auth.cluster_auth.token,"")
}
