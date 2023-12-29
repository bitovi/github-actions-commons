variable "aws_eks_security_group_name_cluster" {}
variable "aws_eks_security_group_name_node" {}
variable "aws_eks_environment" {}
variable "aws_eks_management_cidr" {}
variable "aws_eks_allowed_ports" {}
variable "aws_eks_allowed_ports_cidr" {}
variable "aws_eks_cluster_name" {}
variable "aws_eks_cluster_admin_role_arn" {}
variable "aws_eks_cluster_log_types" {}
variable "aws_eks_cluster_log_retention_days" {}
variable "aws_eks_cluster_log_skip_destroy" {}
variable "aws_eks_cluster_version" {}
variable "aws_eks_instance_type" {}
variable "aws_eks_instance_ami_id" {}
variable "aws_eks_instance_user_data_file" {}
variable "aws_eks_ec2_key_pair" {}
variable "aws_eks_store_keypair_sm" {}
variable "aws_eks_desired_capacity" {}
variable "aws_eks_max_size" {}
variable "aws_eks_min_size" {}
# Others
# VPC inputs
variable "aws_selected_vpc_id" {}
# Others
variable "aws_resource_identifier" {}