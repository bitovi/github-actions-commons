# This file contains the generation of availability zones, subnets and security groups.
# Requires:
#  - aws_ec2

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "vpc_subnets" {
  filter {
    name   = "vpc-id"

    # todo: support a specified vpc id
    # values = [var.vpc_id ? var.vpc_id : data.aws_vpc.default.id]
    values = [data.aws_vpc.default.id]
  }
}

output "aws_default_subnet_ids" {
  description = "The subnet ids from the default vpc"
  value       = data.aws_subnets.vpc_subnets.ids
}

data "aws_region" "current" {}

data "aws_availability_zones" "all" {}

data "aws_security_group" "default" {
  filter {
    name   = "group-name"
    values = ["default"]
  }
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}
