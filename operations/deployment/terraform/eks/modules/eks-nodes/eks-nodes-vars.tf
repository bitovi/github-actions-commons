variable "iam_instance_profile" {}
variable "image_id" {}
variable "instance_type" {}
variable "name_prefix" {}
variable "security_groups" {
    type = list
}
variable "user_data_base64" {}
variable "associate_public_ip_address" {}

variable "desired_capacity" {}
variable "max_size" {}
variable "min_size" {}
variable "asg_name" {}
variable "vpc_zone_identifier" {
    type = list
}
variable "eks_worker_depends_on" {
    type = any
    default = null
}
variable "cluster_name" {}
variable "ec2_key_pair" {}
variable "common_tags" {
    type = map
    default = {}
}