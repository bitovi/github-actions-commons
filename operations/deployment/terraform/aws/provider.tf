provider "kubernetes" {
  alias                  = "eks"
  host                   = module.eks[0].eks_kubernetes_provider_config["host"]
  cluster_ca_certificate = module.eks[0].eks_kubernetes_provider_config["cluster_ca_certificate"]
  token                  = module.eks[0].eks_kubernetes_provider_config["token"]
}