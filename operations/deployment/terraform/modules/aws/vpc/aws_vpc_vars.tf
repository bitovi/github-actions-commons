variable "aws_vpc_create" {}
variable "aws_vpc_id" {}
variable "aws_vpc_cidr_block" {}
variable "aws_vpc_name" {}
variable "aws_vpc_public_subnets" {}
variable "aws_vpc_private_subnets" {}
variable "aws_vpc_availability_zones" {}
variable "aws_ec2_instance_type" {}
variable "aws_ec2_securitu_group_name" {}
#variable "random_integer" {}
variable "aws_resource_identifier" {}
variable "common_tags" {
    type = map
    default = {}
}



#  # Data inputs
#  aws_vpc_default_id                   = data.aws_vpc.default[0].id
#  aws_subnets_vpc_subnets_ids          = data.aws_subnets.vpc_subnets.ids
#  aws_region_current_name              = data.aws_region.current.name
#  # Dependencies
#  aws_vpc_cidr_block_whitelist    = data.aws_vpc.default[0].cidr_block
#  aws_subnet_selected_id              = data.aws_subnet.selected[0].id