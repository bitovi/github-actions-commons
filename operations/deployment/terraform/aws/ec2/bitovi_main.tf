module "aws_certificates" {
  source = "../../modules/aws/certificates"
  count  = var.aws_r53_enable_cert && var.aws_r53_domain_name != "" ? 1 : 0
  # Cert
  aws_r53_create_root_cert = var.aws_r53_create_root_cert
  aws_r53_create_sub_cert  = var.aws_r53_create_sub_cert
  aws_r53_cert_arn         = var.aws_r53_cert_arn
  # R53
  aws_r53_domain_name       = var.aws_r53_domain_name
  aws_r53_sub_domain_name   = var.aws_r53_sub_domain_name
  # Others
  fqdn_provided             = local.fqdn_provided
  common_tags               = local.default_tags
}

module "aws_route53" {
  source = "../../modules/aws/route53"
  count  = var.aws_r53_enable && var.aws_r53_domain_name != "" ? 1 : 0
  # R53 values
  aws_r53_domain_name        = var.aws_r53_domain_name
  aws_r53_sub_domain_name    = var.aws_r53_sub_domain_name
  aws_r53_root_domain_deploy = var.aws_r53_root_domain_deploy
  aws_r53_enable_cert        = var.aws_r53_enable_cert
  # ELB
  aws_elb_dns_name           = module.aws_elb.aws_elb_dns_name
  aws_elb_zone_id            = module.aws_elb.aws_elb_zone_id
  aws_elb_listen_port        = var.aws_elb_listen_port
  # Certs
  aws_certificates_selected_arn = var.aws_r53_enable_cert ? try(module.aws_certificates.selected_arn,"") : ""
  # Others
  fqdn_provided              = local.fqdn_provided
  common_tags                = local.default_tags
}

module "aws_elb" {
  source = "../../modules/aws/elb"
  # We should have a count here, right? 
  aws_elb_security_group_name = var.aws_elb_security_group_name
  aws_elb_app_port            = var.aws_elb_app_port
  aws_elb_app_protocol        = var.aws_elb_app_protocol
  aws_elb_listen_port         = var.aws_elb_listen_port
  aws_elb_listen_protocol     = var.aws_elb_listen_protocol
  aws_elb_healthcheck         = var.aws_elb_healthcheck
  lb_access_bucket_name       = var.lb_access_bucket_name
  # EC2
  aws_instance_server_az = [aws_instance.server.availability_zone]
  aws_instance_server_id = [aws_instance.server.id]
  aws_elb_target_sg_id   = aws_security_group.ec2_security_group.id
  # Certs
  aws_certificates_selected_arn = try(module.aws_certificates.selected_arn,"")
  # Others
  aws_resource_identifier            = var.aws_resource_identifier
  aws_resource_identifier_supershort = var.aws_resource_identifier_supershort
  common_tags                        = local.default_tags
}

module "efs" {
  source = "../../modules/aws/efs"
  count  = local.create_efs ? 1 : 0
  # EFS
  aws_efs_replication_destination = var.aws_efs_replication_destination
  aws_efs_transition_to_inactive  = var.aws_efs_transition_to_inactive
  aws_efs_security_group_name     = var.aws_efs_security_group_name
  aws_efs_enable_backup_policy    = var.aws_efs_enable_backup_policy
  aws_efs_create_replica          = var.aws_efs_create_replica
  # Data inputs
  aws_vpc_default_id      = data.aws_vpc.default.id
  aws_region_current_name = data.aws_region.current.name
  # Others
  aws_resource_identifier = var.aws_resource_identifier
  common_tags             = local.default_tags
}

module "ec2_efs" {
  source = "../../modules/aws/ec2_efs"
  count  = local.create_efs ? var.aws_efs_mount_id != "" ? 1 : 0 : 0
  # EFS
  aws_efs_create                  = var.aws_efs_create
  aws_efs_create_ha               = var.aws_efs_create_ha
  aws_efs_mount_id                = var.aws_efs_mount_id
  aws_efs_mount_security_group_id = var.aws_efs_mount_security_group_id
  aws_efs_zone_mapping            = var.aws_efs_zone_mapping
  aws_efs_ec2_mount_point         = var.aws_efs_ec2_mount_point
  # Other
  ha_zone_mapping  = local.ha_zone_mapping
  ec2_zone_mapping = local.ec2_zone_mapping
  # EC2
  aws_ec2_instance_type           = var.aws_ec2_instance_type
  aws_elb_target_sg_id            = aws_security_group.ec2_security_group.id
  # Docker
  docker_efs_mount_target         = var.docker_efs_mount_target
  # Data inputs
  aws_region_current_name         = data.aws_region.current.name #
  aws_security_group_default_id   = data.aws_security_group.default.id # 
  aws_security_group_ec2_sg_name  = data.aws_security_group.ec2_security_group.name # 
  aws_security_group_ec2_sg_id    = data.aws_security_group.ec2_security_group.id
  # Others
  aws_resource_identifier         = var.aws_resource_identifier
  common_tags                     = local.default_tags
  # Not exposed
  availability_zone               = var.availability_zone 
  app_install_root                = var.app_install_root
  app_repo_name                   = var.app_repo_name
}

module "aurora_rds" {
  source = "../../modules/aws/aurora"
  count  = var.aws_postgres_enable ? 1 : 0
  # RDS
  aws_postgres_engine                  = var.aws_postgres_engine
  aws_postgres_engine_version          = var.aws_postgres_engine_version
  aws_postgres_database_group_family   = var.aws_postgres_database_group_family
  aws_postgres_instance_class          = var.aws_postgres_instance_class
  aws_postgres_security_group_name     = var.aws_postgres_security_group_name
  aws_postgres_subnets                 = var.aws_postgres_subnets
  aws_postgres_cluster_name            = var.aws_postgres_cluster_name
  aws_postgres_database_name           = var.aws_postgres_database_name
  aws_postgres_database_port           = var.aws_postgres_database_port
  aws_postgres_restore_snapshot        = var.aws_postgres_restore_snapshot
  aws_postgres_snapshot_name           = var.aws_postgres_snapshot_name
  aws_postgres_snapshot_overwrite      = var.aws_postgres_snapshot_overwrite
  aws_postgres_database_protection     = var.aws_postgres_database_protection
  aws_postgres_database_final_snapshot = var.aws_postgres_database_final_snapshot
  # Data inputs
  # Others
  aws_resource_identifier            = var.aws_resource_identifier
  aws_resource_identifier_supershort = var.aws_resource_identifier_supershort
  aws_vpc_default_id                 = data.aws_vpc.default.id
  aws_subnets_vpc_subnets_ids        = data.aws_subnets.vpc_subnets.ids
  aws_region_current_name            = data.aws_region.current.name
  common_tags                        = local.default_tags
  # Dependencies
  depends_on = [data.aws_subnets.vpc_subnets]
}

module "eks" {
  source = "../../modules/aws/eks"
  count  = var.aws_eks_create ? 1 : 0
  # EKS
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




