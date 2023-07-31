# This file contains the generation of availability zones, subnets and security groups.
# Requires:
#  - aws_ec2

#data "aws_vpc" "default" {
#  default = true
#}

data "aws_subnets" "vpc_subnets" {
  filter {
    name   = "vpc-id"

    # todo: support a specified vpc id
    # values = [var.vpc_id ? var.vpc_id : data.aws_vpc.default.id]
    values = [data.aws_vpc.default[0].id]
  }
}

#data "aws_region" "current" {}

output "aws_default_subnet_ids" {
  description = "The subnet ids from the default vpc"
  value       = data.aws_subnets.vpc_subnets.ids
}

#output "aws_region_current_name" {
#  description = "The AWS Current region name"
#  value       = data.aws_region.current.name
#}

#output "aws_security_group_default_id" {
#  description = "The AWS Default SG Id"
#  value       = data.aws_security_group.default.id
#}