variable "sg_description" {}
variable "type" {}
variable "from_port" {}
variable "to_port" {}
variable "protocol" {}
variable "cidr" {
    type = list
}
variable "sg_id" {}
variable "common_tags" {
    type = map
    default = {}
}