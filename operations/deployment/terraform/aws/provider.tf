provider "kubernetes" {
  alias                  = "eks"
  host                   = module.eks.eks_kubernetes_provider_config["host"]
  cluster_ca_certificate = module.eks.eks_kubernetes_provider_config["cluster_ca_certificate"]
  token                  = module.eks.eks_kubernetes_provider_config["token"]
}