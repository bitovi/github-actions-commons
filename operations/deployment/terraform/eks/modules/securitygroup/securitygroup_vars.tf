variable "kubernetes_cluster_name" {}
variable "vpc_id" {}
variable "securitygroup_name" {}
variable "securitygroup_description" {}
variable "sg_depends_on" {
  type    = any
  default = null
}
/*
variable "ingress_cidr_blocks" {
  type = list
}
*/
variable "common_tags" {
    type = map
    default = {}
}