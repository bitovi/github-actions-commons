variable "cluster_name" {}
variable "role_arn" {}
variable "security_group_ids" {
    type = list
}
variable "subnet_ids" {
    type = list
}
variable "endpoint_private_access" {
    type = bool
    default = true
}
variable "endpoint_public_access" {
    type = bool
    default = false
}
variable "eks_depends_on" {
  type    = any
  default = null
}
variable "k8s_master_version" {
    type = string
    default = null
}
variable "enabled_cluster_log_types" {
    type = list
    default = []
}
variable "common_tags" {
    type = map
    default = {}
}