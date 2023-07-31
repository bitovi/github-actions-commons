module "ec2" {
  source = "../modules/aws/ec2"
  count  = var.aws_ec2_instance_create ? 1 : 0 
  # EC2
  aws_ec2_ami_filter                  = var.aws_ec2_ami_filter
  aws_ec2_ami_owner                   = var.aws_ec2_ami_owner
  aws_ec2_ami_update                  = var.aws_ec2_ami_update
  aws_ec2_ami_id                      = var.aws_ec2_ami_id
  aws_ec2_instance_type               = var.aws_ec2_instance_type
  aws_ec2_instance_public_ip          = var.aws_ec2_instance_public_ip
  aws_ec2_user_data_replace_on_change = var.aws_ec2_user_data_replace_on_change
  aws_ec2_instance_root_vol_size      = var.aws_ec2_instance_root_vol_size
  aws_ec2_instance_root_vol_preserve  = var.aws_ec2_instance_root_vol_preserve
  aws_ec2_create_keypair_sm           = var.aws_ec2_create_keypair_sm 
  aws_ec2_security_group_name         = var.aws_ec2_security_group_name
  aws_ec2_port_list                   = var.aws_ec2_port_list
  # Data inputs
  aws_ec2_selected_vpc_id             = module.vpc.aws_selected_vpc_id
  aws_subnet_selected_id              = module.vpc.aws_vpc_subnet_selected
  preferred_az                        = module.vpc.preferred_az
  # Others
  aws_resource_identifier             = var.aws_resource_identifier
  aws_resource_identifier_supershort  = var.aws_resource_identifier_supershort
  common_tags                         = local.default_tags
}

module "aws_certificates" {
  source = "../modules/aws/certificates"
  count  = var.aws_ec2_instance_create && var.aws_r53_enable && var.aws_r53_domain_name != "" ? 1 : 0
  # Cert
  aws_r53_cert_arn         = var.aws_r53_cert_arn
  aws_r53_create_root_cert = var.aws_r53_create_root_cert
  aws_r53_create_sub_cert  = var.aws_r53_create_sub_cert
  # R53
  aws_r53_domain_name       = var.aws_r53_domain_name
  aws_r53_sub_domain_name   = var.aws_r53_sub_domain_name
  # Others
  fqdn_provided             = local.fqdn_provided
  common_tags               = local.default_tags
}

module "aws_route53" {
  source = "../modules/aws/route53"
  count  = var.aws_ec2_instance_create && var.aws_r53_enable && var.aws_r53_domain_name != "" ? 1 : 0
  # R53 values
  aws_r53_domain_name           = var.aws_r53_domain_name
  aws_r53_sub_domain_name       = var.aws_r53_sub_domain_name
  aws_r53_root_domain_deploy    = var.aws_r53_root_domain_deploy
  aws_r53_enable_cert           = var.aws_r53_enable_cert
  # ELB
  aws_elb_dns_name              = try(module.aws_elb[0].aws_elb_dns_name,"")
  aws_elb_zone_id               = try(module.aws_elb[0].aws_elb_zone_id,"")
  aws_elb_listen_port           = var.aws_elb_listen_port
  # Certs
  aws_certificates_selected_arn = var.aws_r53_enable_cert && var.aws_r53_domain_name != "" ? module.aws_certificates[0].selected_arn : ""
  # Others
  fqdn_provided                 = local.fqdn_provided
  common_tags                   = local.default_tags
}

module "aws_elb" {
  source = "../modules/aws/elb"
  count  = var.aws_ec2_instance_create ? 1 : 0 
  # We should have a count here, right? 
  aws_elb_security_group_name        = var.aws_elb_security_group_name
  aws_elb_app_port                   = var.aws_elb_app_port
  aws_elb_app_protocol               = var.aws_elb_app_protocol
  aws_elb_listen_port                = var.aws_elb_listen_port
  aws_elb_listen_protocol            = var.aws_elb_listen_protocol
  aws_elb_healthcheck                = var.aws_elb_healthcheck
  lb_access_bucket_name              = var.lb_access_bucket_name
  # EC2
  aws_instance_server_az             = [module.vpc.preferred_az]
  aws_instance_server_id             = module.ec2[0].aws_instance_server_id
  aws_elb_target_sg_id               = module.ec2[0].aws_security_group_ec2_sg_id 
  # Certs
  aws_certificates_selected_arn      = var.aws_r53_enable_cert && var.aws_r53_domain_name != "" ? module.aws_certificates[0].selected_arn : ""
  # Others
  aws_resource_identifier            = var.aws_resource_identifier
  aws_resource_identifier_supershort = var.aws_resource_identifier_supershort
  common_tags                        = local.default_tags
}

module "efs" {
  source = "../modules/aws/efs"
  count  = local.create_efs ? 1 : 0
# EFS
  aws_efs_replication_destination = var.aws_efs_replication_destination
  aws_efs_transition_to_inactive  = var.aws_efs_transition_to_inactive
  aws_efs_security_group_name     = var.aws_efs_security_group_name
  aws_efs_enable_backup_policy    = var.aws_efs_enable_backup_policy
  aws_efs_create_replica          = var.aws_efs_create_replica
  # EC2
  aws_ec2_instance_create         = var.aws_ec2_instance_create
  # VPC inputs
  aws_vpc_id                      = module.vpc.aws_selected_vpc_id
  aws_vpc_cidr_block_whitelist    = module.vpc.aws_vpc_cidr_block
  aws_region_current_name         = module.vpc.aws_region_current_name
  # Others
  aws_resource_identifier         = var.aws_resource_identifier
  common_tags                     = local.default_tags
}

module "ec2_efs" {
  source = "../modules/aws/ec2_efs"
  count  = var.aws_ec2_instance_create && local.create_efs ? var.aws_efs_mount_id != "" ? 1 : 0 : 0
  # EFS
  aws_efs_create                  = var.aws_efs_create
  aws_efs_create_ha               = var.aws_efs_create_ha
  aws_efs_mount_id                = var.aws_efs_mount_id
  aws_efs_zone_mapping            = var.aws_efs_zone_mapping
  aws_efs_ec2_mount_point         = var.aws_efs_ec2_mount_point
  # Other
  ha_zone_mapping                 = module.vpc.ha_zone_mapping
  ec2_zone_mapping                = module.vpc.ec2_zone_mapping
  # Docker
  docker_efs_mount_target         = var.docker_efs_mount_target
  # Data inputs
  aws_region_current_name         = module.vpc.aws_region_current_name #
  aws_security_group_efs_id       = module.efs[0].aws_security_group_efs_id
  aws_efs_fs_id                   = module.efs[0].aws_efs_fs_id
  # Others
  common_tags                     = local.default_tags
  # Not exposed
  app_install_root                = var.app_install_root
  app_repo_name                   = var.app_repo_name
  # Dependencies
  depends_on = [module.efs]
}


module "aurora_rds" {
  source = "../modules/aws/aurora"
  count  = var.aws_aurora_enable ? 1 : 0
  # RDS
  aws_aurora_engine                  = var.aws_aurora_engine
  aws_aurora_engine_version          = var.aws_aurora_engine_version
  aws_aurora_database_group_family   = var.aws_aurora_database_group_family
  aws_aurora_instance_class          = var.aws_aurora_instance_class
  aws_aurora_security_group_name     = var.aws_aurora_security_group_name
  aws_aurora_subnets                 = var.aws_aurora_subnets
  aws_aurora_cluster_name            = var.aws_aurora_cluster_name
  aws_aurora_database_name           = var.aws_aurora_database_name
  aws_aurora_database_port           = var.aws_aurora_database_port
  aws_aurora_restore_snapshot        = var.aws_aurora_restore_snapshot
  aws_aurora_snapshot_name           = var.aws_aurora_snapshot_name
  aws_aurora_snapshot_overwrite      = var.aws_aurora_snapshot_overwrite
  aws_aurora_database_protection     = var.aws_aurora_database_protection
  aws_aurora_database_final_snapshot = var.aws_aurora_database_final_snapshot
  # Data inputs
  aws_vpc_default_id                   = module.vpc.aws_selected_vpc_id
  aws_subnets_vpc_subnets_ids          = module.vpc.aws_selected_vpc_subnets
  aws_region_current_name              = module.vpc.aws_region_current_name
  # Others
  aws_resource_identifier              = var.aws_resource_identifier
  aws_resource_identifier_supershort   = var.aws_resource_identifier_supershort
  common_tags                          = local.default_tags
  # Dependencies
  depends_on = [module.vpc]
}

module "vpc" {
  source                      = "../modules/aws/vpc"
  aws_vpc_create              = var.aws_vpc_create
  aws_vpc_id                  = var.aws_vpc_id 
  aws_vpc_cidr_block          = var.aws_vpc_cidr_block
  aws_vpc_name                = var.aws_vpc_name
  aws_vpc_public_subnets      = var.aws_vpc_public_subnets
  aws_vpc_private_subnets     = var.aws_vpc_private_subnets
  aws_vpc_availability_zones  = var.aws_vpc_availability_zones
  # Data inputs
  aws_ec2_instance_type       = var.aws_ec2_instance_type
  aws_ec2_securitu_group_name = try([module.ec2[0].aws_security_group_ec2_sg_name],[""])
  # Others
  aws_resource_identifier     = var.aws_resource_identifier
  common_tags                 = local.default_tags
}

#module "eks" {
#  source = "../modules/aws/eks"
#  count  = var.aws_eks_create ? 1 : 0
#  # EKS
#  #aws_eks_create                     = var.aws_eks_create
#  aws_eks_region                     = var.aws_eks_region
#  aws_eks_security_group_name_master = var.aws_eks_security_group_name_master
#  aws_eks_security_group_name_worker = var.aws_eks_security_group_name_worker
#  aws_eks_environment                = var.aws_eks_environment
#  aws_eks_stackname                  = var.aws_eks_stackname
#  aws_eks_cidr_block                 = var.aws_eks_cidr_block
#  aws_eks_workstation_cidr           = var.aws_eks_workstation_cidr
#  aws_eks_availability_zones         = var.aws_eks_availability_zones
#  aws_eks_private_subnets            = var.aws_eks_private_subnets
#  aws_eks_public_subnets             = var.aws_eks_public_subnets
#  aws_eks_cluster_name               = var.aws_eks_cluster_name
#  aws_eks_cluster_log_types          = var.aws_eks_cluster_log_types
#  aws_eks_cluster_version            = var.aws_eks_cluster_version
#  aws_eks_instance_type              = var.aws_eks_instance_type
#  aws_eks_instance_ami_id            = var.aws_eks_instance_ami_id
#  aws_eks_instance_user_data_file    = var.aws_eks_instance_user_data_file
#  aws_eks_ec2_key_pair               = var.aws_eks_ec2_key_pair
#  aws_eks_store_keypair_sm           = var.aws_eks_store_keypair_sm
#  aws_eks_desired_capacity           = var.aws_eks_desired_capacity
#  aws_eks_max_size                   = var.aws_eks_max_size
#  aws_eks_min_size                   = var.aws_eks_min_size
#  # Hidden
#  aws_eks_vpc_name = var.aws_eks_vpc_name
#  # Others
#  aws_resource_identifier = var.aws_resource_identifier
#  common_tags             = local.default_tags
#}

module "ansible" {
  source = "../modules/aws/ansible"
  count  = var.aws_ec2_instance_create ? 1 : 0
  aws_efs_enable          = var.aws_efs_enable
  app_repo_name           = var.app_repo_name
  app_install_root        = var.app_install_root
  aws_resource_identifier = var.aws_resource_identifier
  docker_remove_orphans   = var.docker_remove_orphans
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
  ec2_no_dns_url = try(module.aws_elb[0].aws_elb_dns_name,module.ec2[0].instance_public_dns,module.ec2[0].instance_public_ip,"")
  ec2_no_dns_url_fqdn = local.ec2_no_dns_url != "" ? "http://${local.ec2_no_dns_url}" : ""
}

output "instance_public_dns" {
  description = "Public DNS address of the EC2 instance"
  value       = try(module.ec2[0].instance_public_dns,"")
}

output "instance_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = try(module.ec2[0].instance_public_ip,"")
}

output "aws_elb_dns_name" {
  description = "Public DNS address of the LB"
  value       = try(module.aws_elb[0].aws_elb_dns_name,"")
}

output "application_public_dns" {
  description = "Public DNS address for the application or load balancer public DNS"
  value       = try(module.aws_route53[0].vm_url,"")
}

output "vm_url" {
  value = try(module.aws_route53[0].vm_url,local.ec2_no_dns_url_fqdn)
}