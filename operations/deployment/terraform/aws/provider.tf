provider "kubernetes" {
  alias                  = "eks"
  host                   = try(module.eks[0].eks_kubernetes_provider_config["host"],null)
  cluster_ca_certificate = try(module.eks[0].eks_kubernetes_provider_config["cluster_ca_certificate"],null)
  token                  = try(module.eks[0].eks_kubernetes_provider_config["token"],null)
}