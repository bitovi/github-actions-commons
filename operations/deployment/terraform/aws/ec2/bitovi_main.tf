module "aws_certificates" {
  source = "../../modules/aws/certificates"
  count  = var.aws_r53_enable_cert ? 1 : 0
  # Cert
  aws_r53_create_root_cert = var.aws_r53_create_root_cert
  aws_r53_create_sub_cert  = var.aws_r53_create_sub_cert
  aws_r53_cert_arn         = var.aws_r53_cert_arn
  # R53
  aws_r53_domain_name       = var.aws_r53_domain_name
  aws_r53_sub_domain_name   = var.aws_r53_sub_domain_name
  # Others
  aws_route53_zone_id       = module.aws_route53.zone_id
  fqdn_provided             = local.fqdn_provided
  common_tags               = local.default_tags
}

module "aws_route53" {
  source = "../../modules/aws/route53"
  count  = var.aws_r53_enable ? 1 : 0
  # R53 values
  aws_r53_domain_name        = var.aws_r53_domain_name
  aws_r53_sub_domain_name    = var.aws_r53_sub_domain_name
  aws_r53_root_domain_deploy = var.aws_r53_root_domain_deploy
  aws_r53_enable_cert        = var.aws_r53_enable_cert
  # ELB
  aws_elb_dns_name           = aws_elb.vm_lb.dns_name
  aws_elb_zone_id            = aws_elb.vm_lb.zone_id
  aws_elb_listen_port        = var.aws_elb_listen_port
  # Certs
  aws_certificates_selected_arn = var.aws_r53_enable_cert ? module.aws_certificates.selected_arn : ""
  # Others
  fqdn_provided              = local.fqdn_provided
  common_tags                = local.default_tags
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
  aws_subnets_vpc_subnets_ids = data.aws_subnets.vpc_subnets.ids
  # Others
  aws_resource_identifier            = var.aws_resource_identifier
  aws_resource_identifier_supershort = var.aws_resource_identifier_supershort
  aws_vpc_default_id                 = data.aws_vpc.default.id
  aws_region_current_name            = data.aws_region.current.name
  common_tags                        = local.default_tags
  # Dependencies
  depends_on = [data.aws_subnets.vpc_subnets]
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




