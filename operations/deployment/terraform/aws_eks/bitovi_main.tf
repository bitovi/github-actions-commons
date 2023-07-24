module "eks" {
  source = "../modules/aws/eks"
  aws_eks_region                     = var.aws_eks_region
  aws_eks_security_group_name_master = var.aws_eks_security_group_name_master
  aws_eks_security_group_name_worker = var.aws_eks_security_group_name_worker
  aws_eks_environment                = var.aws_eks_environment
  aws_eks_stackname                  = var.aws_eks_stackname
  aws_eks_cidr_block                 = var.aws_eks_cidr_block
  aws_eks_workstation_cidr           = var.aws_eks_workstation_cidr
  aws_eks_availability_zones         = var.aws_eks_availability_zones
  aws_eks_private_subnets            = var.aws_eks_private_subnets
  aws_eks_public_subnets             = var.aws_eks_public_subnets
  aws_eks_cluster_name               = var.aws_eks_cluster_name
  aws_eks_cluster_log_types          = var.aws_eks_cluster_log_types
  aws_eks_cluster_version            = var.aws_eks_cluster_version
  aws_eks_instance_type              = var.aws_eks_instance_type
  aws_eks_instance_ami_id            = var.aws_eks_instance_ami_id
  aws_eks_instance_user_data_file    = var.aws_eks_instance_user_data_file
  aws_eks_ec2_key_pair               = var.aws_eks_ec2_key_pair
  aws_eks_store_keypair_sm           = var.aws_eks_store_keypair_sm
  aws_eks_desired_capacity           = var.aws_eks_desired_capacity
  aws_eks_max_size                   = var.aws_eks_max_size
  aws_eks_min_size                   = var.aws_eks_min_size
  # Hidden
  aws_eks_vpc_name = var.aws_eks_vpc_name
  # Others
  aws_resource_identifier = var.aws_resource_identifier
  common_tags             = local.default_tags
}

module "ansible" {
  source = "../modules/aws/ansible"
  count  = var.aws_ec2_instance_create ? 1 : 0
  aws_efs_enable          = var.aws_efs_enable
  app_repo_name           = var.app_repo_name
  app_install_root        = var.app_install_root
  aws_resource_identifier = var.aws_resource_identifier
  aws_efs_ec2_mount_point = var.aws_efs_ec2_mount_point
  aws_efs_mount_target    = var.aws_efs_mount_target
  docker_efs_mount_target = var.docker_efs_mount_target
  aws_ec2_efs_url         = try(module.ec2_efs[0].efs_url,"")
  # Data inputs
  private_key_filename    = module.ec2[0].private_key_filename
  # Dependencies
  depends_on = [module.ec2]
}

locals {
  default_tags = merge(local.aws_tags, var.aws_additional_tags)
  fqdn_provided = (
    (var.aws_r53_domain_name != "") ?
    (var.aws_r53_sub_domain_name != "" ?
      true :
      var.aws_r53_root_domain_deploy ? true : false
    ) :
    false
  )
  create_efs = var.aws_efs_create == true ? true : (var.aws_efs_create_ha == true ? true : false)
}

output "instance_public_dns" {
  description = "Public DNS address of the EC2 instance"
  value       = try(module.ec2[0].instance_public_dns,"")
}

output "instance_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = try(module.ec2[0].instance_public_ip,"")
}

output "lb_public_dns" {
  description = "Public DNS address of the LB"
  value       = try(module.aws_elb.aws_elb_dns_name,"")
}

output "application_public_dns" {
  description = "Public DNS address for the application or load balancer public DNS"
  value       = try(module.aws_route53[0].vm_url,"")
}

output "vm_url" {
  value = try(module.aws_route53[0].vm_url,"")
}