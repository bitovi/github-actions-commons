variable "vpc_name" {}
variable "cidr" {}
variable "availability_zones" {}
variable "private_subnets" {}
variable "public_subnets" {}
variable "kubernetes_cluster_name" {}
variable "environment" {}
variable "create_vpc" {
  type = bool
  default = true
}
variable "common_tags" {
    type = map
    default = {}
}