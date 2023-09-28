# EC2
variable "aws_ec2_ami_filter" {}
variable "aws_ec2_ami_owner" {}
variable "aws_ec2_ami_update" {}
variable "aws_ec2_ami_id" {}
variable "aws_ec2_instance_type" {}
variable "aws_ec2_instance_public_ip" {}
variable "aws_ec2_user_data_replace_on_change" {}
variable "aws_ec2_instance_root_vol_size" {}
variable "aws_ec2_instance_root_vol_preserve" {}
variable "aws_ec2_create_keypair_sm" {}
variable "aws_ec2_security_group_name" {}
variable "aws_ec2_port_list" {}
# Data inputs
variable "aws_ec2_selected_vpc_id" {}
variable "aws_vpc_dns_enabled" {}
variable "aws_subnet_selected_id" {}
variable "preferred_az" {}
variable "ec2_tags" {
    type = map
    default = {}
}
# Others
variable "aws_resource_identifier" {}
variable "aws_resource_identifier_supershort" {}