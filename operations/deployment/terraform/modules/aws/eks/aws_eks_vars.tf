
variable "aws_eks_region" {}
variable "aws_eks_security_group_name_master" {}
variable "aws_eks_security_group_name_worker" {}
variable "aws_eks_environment" {}
variable "aws_eks_stackname" {}
variable "aws_eks_cidr_block" {}
variable "aws_eks_workstation_cidr" {}
variable "aws_eks_availability_zones" {}
variable "aws_eks_private_subnets" {}
variable "aws_eks_public_subnets" {}
variable "aws_eks_cluster_name" {}
variable "aws_eks_cluster_log_types" {}
variable "aws_eks_cluster_version" {}
variable "aws_eks_instance_type" {}
variable "aws_eks_instance_ami_id" {}
variable "aws_eks_instance_user_data_file" {}
variable "aws_eks_ec2_key_pair" {}
variable "aws_eks_store_keypair_sm" {}
variable "aws_eks_desired_capacity" {}
variable "aws_eks_max_size" {}
variable "aws_eks_min_size" {}
# Hidden
variable "aws_eks_vpc_name" {}
# Others
variable "aws_resource_identifier" {}
variable "common_tags" {
    type = map
    default = {}
}