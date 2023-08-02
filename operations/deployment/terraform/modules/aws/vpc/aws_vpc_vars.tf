variable "aws_vpc_create" {}
variable "aws_vpc_id" {}
variable "aws_vpc_subnet_id" {}
variable "aws_vpc_cidr_block" {}
variable "aws_vpc_name" {}
variable "aws_vpc_public_subnets" {}
variable "aws_vpc_private_subnets" {}
variable "aws_vpc_availability_zones" {}
variable "aws_ec2_instance_type" {}
variable "aws_ec2_security_group_name" {}
variable "aws_resource_identifier" {}
variable "common_tags" {
    type = map
    default = {}
}