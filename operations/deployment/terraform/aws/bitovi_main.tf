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
  aws_ec2_iam_instance_profile        = var.aws_ec2_iam_instance_profile
  aws_ec2_port_list                   = var.aws_ec2_port_list
  # Data inputs
  aws_ec2_selected_vpc_id             = module.vpc.aws_selected_vpc_id
  aws_vpc_dns_enabled                 = module.vpc.aws_vpc_dns_enabled
  aws_subnet_selected_id              = module.vpc.aws_vpc_subnet_selected
  preferred_az                        = module.vpc.preferred_az
  # Others
  aws_resource_identifier             = var.aws_resource_identifier
  aws_resource_identifier_supershort  = var.aws_resource_identifier_supershort
  ec2_tags                            = local.ec2_tags
  depends_on = [module.vpc]

  providers = {
    aws = aws.ec2
  }
}

module "ec2_sg_to_rds" {
  source = "../modules/aws/sg/add_rule"
  count  = var.aws_ec2_instance_create && var.aws_rds_db_enable ? 1 : 0
  # Inputs 
  sg_type                  = "ingress"
  sg_rule_description      = "${var.aws_resource_identifier} - EC2 Incoming"
  sg_rule_from_port        = try(module.db_proxy_rds[0].db_proxy_port,module.rds[0].db_port)
  sg_rule_to_port          = try(module.db_proxy_rds[0].db_proxy_port,module.rds[0].db_port)
  sg_rule_protocol         = "tcp"
  source_security_group_id = module.ec2[0].aws_security_group_ec2_sg_id
  target_security_group_id = try(module.db_proxy_rds[0].db_proxy_sg_id,module.rds[0].rds_sg_id)
  
  depends_on = [ module.ec2,module.rds ]
}

module "efs_to_ec2_sg" {
  source = "../modules/aws/sg/add_rule"
  count  = var.aws_ec2_instance_create && var.aws_efs_enable && (var.aws_efs_fs_id == null) ? 1 : 0
  # Inputs 
  sg_type                  = "ingress"
  sg_rule_description      = "${var.aws_resource_identifier} - EC2 Incoming"
  sg_rule_from_port        = 2049
  sg_rule_to_port          = 2049
  sg_rule_protocol         = "tcp"
  source_security_group_id = try(module.efs[0].aws_efs_sg_id)
  target_security_group_id = module.ec2[0].aws_security_group_ec2_sg_id
  depends_on = [ module.ec2,module.efs ]
}

module "aws_certificates" {
  source = "../modules/aws/certificates"
  count  = ( var.aws_ec2_instance_create || var.aws_ecs_enable ) && var.aws_r53_enable && var.aws_r53_domain_name != "" ? 1 : 0
  # Cert
  aws_r53_cert_arn         = var.aws_r53_cert_arn
  aws_r53_create_root_cert = var.aws_r53_create_root_cert
  aws_r53_create_sub_cert  = var.aws_r53_create_sub_cert
  # R53
  aws_r53_domain_name       = var.aws_r53_domain_name
  aws_r53_sub_domain_name   = var.aws_r53_sub_domain_name
  # Others
  fqdn_provided             = local.fqdn_provided
  
  providers = {
    aws = aws.r53
  }
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
  # Certs
  aws_certificates_selected_arn = var.aws_r53_enable_cert && var.aws_r53_domain_name != "" ? module.aws_certificates[0].selected_arn : ""
  # Others
  fqdn_provided                 = local.fqdn_provided

  providers = {
    aws = aws.r53
  }
}

module "aws_elb" {
  source = "../modules/aws/elb"
  count  = var.aws_ec2_instance_create && var.aws_elb_create ? 1 : 0 
  # ELB Values
  aws_elb_security_group_name        = var.aws_elb_security_group_name
  aws_elb_app_port                   = var.aws_elb_app_port
  aws_elb_app_protocol               = var.aws_elb_app_protocol
  aws_elb_listen_port                = var.aws_elb_listen_port
  aws_elb_listen_protocol            = var.aws_elb_listen_protocol
  aws_elb_healthcheck                = var.aws_elb_healthcheck
  aws_elb_access_log_bucket_name     = var.aws_elb_access_log_bucket_name
  aws_elb_access_log_expire          = var.aws_elb_access_log_expire
  # EC2
  aws_instance_server_az             = [module.vpc.preferred_az]
  aws_vpc_selected_id                = module.vpc.aws_selected_vpc_id
  aws_vpc_subnet_selected            = module.vpc.aws_vpc_subnet_selected
  aws_instance_server_id             = module.ec2[0].aws_instance_server_id
  aws_elb_target_sg_id               = module.ec2[0].aws_security_group_ec2_sg_id 
  # Certs
  aws_certificates_selected_arn      = var.aws_r53_enable_cert && var.aws_r53_domain_name != "" ? module.aws_certificates[0].selected_arn : ""
  # Others
  aws_resource_identifier            = var.aws_resource_identifier
  aws_resource_identifier_supershort = var.aws_resource_identifier_supershort
  # Module dependencies
  depends_on = [module.vpc,module.ec2]
  
  providers = {
    aws = aws.elb
  }
}

module "efs" {
  source = "../modules/aws/efs"
  count  = var.aws_efs_enable ? 1 : 0
  # EFS
  aws_efs_create                  = var.aws_efs_create
  aws_efs_fs_id                   = var.aws_efs_fs_id
  aws_efs_create_mount_target     = var.aws_efs_create_mount_target
  aws_efs_create_ha               = var.aws_efs_create_ha

  aws_efs_vol_encrypted           = var.aws_efs_vol_encrypted
  aws_efs_kms_key_id              = var.aws_efs_kms_key_id
  aws_efs_performance_mode        = var.aws_efs_performance_mode
  aws_efs_throughput_mode         = var.aws_efs_throughput_mode
  aws_efs_throughput_speed        = var.aws_efs_throughput_speed
  aws_efs_security_group_name     = var.aws_efs_security_group_name
  aws_efs_allowed_security_groups = var.aws_efs_allowed_security_groups
  aws_efs_ingress_allow_all       = var.aws_efs_ingress_allow_all
  aws_efs_create_replica          = var.aws_efs_create_replica
  aws_efs_replication_destination = var.aws_efs_replication_destination
  aws_efs_enable_backup_policy    = var.aws_efs_enable_backup_policy
  aws_efs_transition_to_inactive  = var.aws_efs_transition_to_inactive
  
  # VPC Inputs
  aws_selected_vpc_id                    = module.vpc.aws_selected_vpc_id
  aws_selected_subnet_id                 = module.vpc.aws_vpc_subnet_selected
  aws_resource_identifier                = var.aws_resource_identifier
  depends_on = [module.vpc]

  providers = {
    aws = aws.efs
  }
}

#module "efs" {
#  source = "../modules/aws/efs"
#  count  = var.aws_efs_enable ? 1 : 0
#  # EFS
#  aws_efs_create                  = var.aws_efs_create
#  aws_efs_create_ha               = var.aws_efs_create_ha
#  aws_efs_fs_id                   = var.aws_efs_fs_id
#  #aws_efs_vpc_id                  = var.aws_efs_vpc_id
#  #aws_efs_subnet_ids              = var.aws_efs_subnet_ids
#  aws_efs_security_group_name     = var.aws_efs_security_group_name
#  aws_efs_create_replica          = var.aws_efs_create_replica
#  aws_efs_replication_destination = var.aws_efs_replication_destination
#  aws_efs_enable_backup_policy    = var.aws_efs_enable_backup_policy
#  aws_efs_transition_to_inactive  = var.aws_efs_transition_to_inactive
#  # VPC inputs
#  aws_selected_vpc_id             = module.vpc.aws_selected_vpc_id
#  aws_selected_subnet_id          = module.vpc.aws_vpc_subnet_selected
#  aws_selected_az                 = module.vpc.preferred_az
#  aws_selected_az_list            = module.vpc.availability_zones
#  # Others
#  aws_resource_identifier         = var.aws_resource_identifier
#  depends_on = [module.vpc]
#
#  providers = {
#    aws = aws.efs
#  }
#}

module "rds" {
  source = "../modules/aws/rds"
  count  = var.aws_rds_db_enable ? 1 : 0
  # RDS
  aws_rds_db_name                        = var.aws_rds_db_name
  aws_rds_db_user                        = var.aws_rds_db_user
  aws_rds_db_identifier                  = var.aws_rds_db_identifier != "" ? var.aws_rds_db_identifier : lower(var.aws_resource_identifier)
  aws_rds_db_engine                      = var.aws_rds_db_engine
  aws_rds_db_engine_version              = var.aws_rds_db_engine_version
  aws_rds_db_ca_cert_identifier          = var.aws_rds_db_ca_cert_identifier
  aws_rds_db_security_group_name         = var.aws_rds_db_security_group_name
  aws_rds_db_allowed_security_groups     = var.aws_rds_db_allowed_security_groups
  aws_rds_db_ingress_allow_all           = var.aws_rds_db_ingress_allow_all
  aws_rds_db_publicly_accessible         = var.aws_rds_db_publicly_accessible
  aws_rds_db_port                        = var.aws_rds_db_port
  aws_rds_db_subnets                     = var.aws_rds_db_subnets
  aws_rds_db_allocated_storage           = var.aws_rds_db_allocated_storage
  aws_rds_db_max_allocated_storage       = var.aws_rds_db_max_allocated_storage
  aws_rds_db_storage_encrypted           = var.aws_rds_db_storage_encrypted
  aws_rds_db_storage_type                = var.aws_rds_db_storage_type
  aws_rds_db_kms_key_id                  = var.aws_rds_db_kms_key_id
  aws_rds_db_instance_class              = var.aws_rds_db_instance_class
  aws_rds_db_final_snapshot              = var.aws_rds_db_final_snapshot
  aws_rds_db_restore_snapshot_identifier = var.aws_rds_db_restore_snapshot_identifier
  aws_rds_db_cloudwatch_logs_exports     = var.aws_rds_db_cloudwatch_logs_exports
  aws_rds_db_multi_az                    = var.aws_rds_db_multi_az
  aws_rds_db_maintenance_window          = var.aws_rds_db_maintenance_window
  aws_rds_db_apply_immediately           = var.aws_rds_db_apply_immediately
  # Others
  #aws_ec2_security_group                 = var.aws_ec2_instance_create ? module.ec2[0].aws_security_group_ec2_sg_id : ""
  aws_selected_vpc_id                    = module.vpc.aws_selected_vpc_id
  aws_subnets_vpc_subnets_ids            = module.vpc.aws_selected_vpc_subnets
  aws_resource_identifier                = var.aws_resource_identifier
  aws_resource_identifier_supershort     = var.aws_resource_identifier_supershort
  # Dependencies
  depends_on = [module.vpc]

  providers = {
    aws = aws.rds
  }
}

module "db_proxy_rds" {
  source = "../modules/aws/db_proxy"
  count  = var.aws_rds_db_proxy ? 1 : 0
  # PROXY
  aws_aurora_proxy                            = var.aws_aurora_proxy
  aws_rds_db_proxy                            = var.aws_rds_db_proxy
  aws_db_proxy_name                           = var.aws_db_proxy_name != "" ? var.aws_db_proxy_name : lower(var.aws_resource_identifier)
  aws_db_proxy_database_id                    = module.rds[0].db_id
  aws_db_proxy_cluster                        = false
  aws_db_proxy_secret_name                    = module.rds[0].db_secret_name
  aws_db_proxy_client_password_auth_type      = var.aws_db_proxy_client_password_auth_type
  aws_db_proxy_tls                            = var.aws_db_proxy_tls
  aws_db_proxy_security_group_name            = var.aws_db_proxy_security_group_name
  aws_db_proxy_database_security_group_allow  = var.aws_db_proxy_database_security_group_allow
  aws_db_proxy_allowed_security_group         = var.aws_db_proxy_allowed_security_group
  aws_db_proxy_allow_all_incoming             = var.aws_db_proxy_allow_all_incoming
  aws_db_proxy_cloudwatch_enable              = var.aws_db_proxy_cloudwatch_enable
  aws_db_proxy_cloudwatch_retention_days      = var.aws_db_proxy_cloudwatch_retention_days
  # Others
  #aws_ec2_security_group                      = var.aws_ec2_instance_create ? module.ec2[0].aws_security_group_ec2_sg_id : ""
  aws_selected_vpc_id                         = module.vpc.aws_selected_vpc_id
  aws_selected_subnets                        = module.vpc.aws_selected_vpc_subnets
  aws_resource_identifier                     = var.aws_resource_identifier
  aws_resource_identifier_supershort          = var.aws_resource_identifier_supershort
  incoming_random_string                      = module.rds[0].random_string
  # Dependencies
  depends_on = [module.vpc,module.rds]

  providers = {
    aws = aws.db_proxy
  }
}

module "aurora_rds" {
  source = "../modules/aws/aurora"
  count  = var.aws_aurora_enable ? 1 : 0
  # DB params
  aws_aurora_cluster_name              = var.aws_aurora_cluster_name
  aws_aurora_engine                    = var.aws_aurora_engine
  aws_aurora_engine_version            = var.aws_aurora_engine_version
  aws_aurora_engine_mode               = var.aws_aurora_engine_mode
  aws_aurora_availability_zones        = var.aws_aurora_availability_zones
  aws_aurora_cluster_apply_immediately = var.aws_aurora_cluster_apply_immediately
  # Storage 
  aws_aurora_allocated_storage         = var.aws_aurora_allocated_storage
  aws_aurora_storage_encrypted         = var.aws_aurora_storage_encrypted
  aws_aurora_kms_key_id                = var.aws_aurora_kms_key_id
  aws_aurora_storage_type              = var.aws_aurora_storage_type
  aws_aurora_storage_iops              = var.aws_aurora_storage_iops
  # DB Details
  aws_aurora_database_name             = var.aws_aurora_database_name
  aws_aurora_master_username           = var.aws_aurora_master_username
  aws_aurora_database_group_family     = var.aws_aurora_database_group_family
  aws_aurora_iam_auth_enabled          = var.aws_aurora_iam_auth_enabled
  aws_aurora_iam_roles                 = var.aws_aurora_iam_roles
  # Net
  aws_aurora_cluster_db_instance_class = var.aws_aurora_cluster_db_instance_class
  aws_aurora_security_group_name       = var.aws_aurora_security_group_name
  aws_aurora_allowed_security_groups   = var.aws_aurora_allowed_security_groups
  aws_aurora_ingress_allow_all         = var.aws_aurora_ingress_allow_all
  aws_aurora_subnets                   = var.aws_aurora_subnets
  aws_aurora_database_port             = var.aws_aurora_database_port
  aws_aurora_db_publicly_accessible    = var.aws_aurora_db_publicly_accessible
  # Backup & maint
  aws_aurora_cloudwatch_enable         = var.aws_aurora_cloudwatch_enable
  aws_aurora_cloudwatch_log_type       = var.aws_aurora_cloudwatch_log_type
  aws_aurora_cloudwatch_retention_days = var.aws_aurora_cloudwatch_retention_days
  aws_aurora_backtrack_window          = var.aws_aurora_backtrack_window
  aws_aurora_backup_retention_period   = var.aws_aurora_backup_retention_period
  aws_aurora_backup_window             = var.aws_aurora_backup_window
  aws_aurora_maintenance_window        = var.aws_aurora_maintenance_window
  aws_aurora_database_final_snapshot   = var.aws_aurora_database_final_snapshot
  aws_aurora_deletion_protection       = var.aws_aurora_deletion_protection
  aws_aurora_delete_auto_backups       = var.aws_aurora_delete_auto_backups
  aws_aurora_restore_snapshot_id       = var.aws_aurora_restore_snapshot_id
  aws_aurora_restore_to_point_in_time  = var.aws_aurora_restore_to_point_in_time
  aws_aurora_snapshot_name             = var.aws_aurora_snapshot_name
  aws_aurora_snapshot_overwrite        = var.aws_aurora_snapshot_overwrite
  # DB Parameters
  aws_aurora_db_instances_count        = var.aws_aurora_db_instances_count
  aws_aurora_db_instance_class         = var.aws_aurora_db_instance_class
  aws_aurora_db_apply_immediately      = var.aws_aurora_db_apply_immediately
  aws_aurora_db_ca_cert_identifier     = var.aws_aurora_db_ca_cert_identifier
  aws_aurora_db_maintenance_window     = var.aws_aurora_db_maintenance_window
  # Incoming
  #aws_ec2_security_group               = var.aws_ec2_instance_create ? module.ec2[0].aws_security_group_ec2_sg_id : ""
  aws_selected_vpc_id                  = module.vpc.aws_selected_vpc_id
  aws_subnets_vpc_subnets_ids          = module.vpc.aws_selected_vpc_subnets
  aws_resource_identifier              = var.aws_resource_identifier
  aws_resource_identifier_supershort   = var.aws_resource_identifier_supershort
  # Dependencies
  depends_on = [module.vpc,module.ec2]

  providers = {
    aws = aws.aurora
  }
}

module "db_proxy_aurora" {
  source = "../modules/aws/db_proxy"
  count  = var.aws_aurora_proxy ? 1 : 0
  # PROXY
  aws_aurora_proxy                            = var.aws_aurora_proxy
  aws_rds_db_proxy                            = var.aws_rds_db_proxy
  aws_db_proxy_name                           = var.aws_db_proxy_name != "" ? var.aws_db_proxy_name : lower(var.aws_resource_identifier)
  aws_db_proxy_database_id                    = module.aurora_rds[0].aurora_db_id
  aws_db_proxy_cluster                        = true
  aws_db_proxy_secret_name                    = module.aurora_rds[0].aurora_secret_name
  aws_db_proxy_client_password_auth_type      = var.aws_db_proxy_client_password_auth_type
  aws_db_proxy_tls                            = var.aws_db_proxy_tls
  aws_db_proxy_security_group_name            = var.aws_db_proxy_security_group_name
  aws_db_proxy_database_security_group_allow  = var.aws_db_proxy_database_security_group_allow
  aws_db_proxy_allowed_security_group         = var.aws_db_proxy_allowed_security_group
  aws_db_proxy_allow_all_incoming             = var.aws_db_proxy_allow_all_incoming
  aws_db_proxy_cloudwatch_enable              = var.aws_db_proxy_cloudwatch_enable
  aws_db_proxy_cloudwatch_retention_days      = var.aws_db_proxy_cloudwatch_retention_days
  # Others
  #aws_ec2_security_group                      = var.aws_ec2_instance_create ? module.ec2[0].aws_security_group_ec2_sg_id : ""
  aws_selected_vpc_id                         = module.vpc.aws_selected_vpc_id
  aws_selected_subnets                        = module.vpc.aws_selected_vpc_subnets
  aws_resource_identifier                     = var.aws_resource_identifier
  aws_resource_identifier_supershort          = var.aws_resource_identifier_supershort
  incoming_random_string                      = module.aurora_rds[0].random_string
  # Dependencies
  depends_on = [module.vpc,module.aurora_rds,module.ec2]

  providers = {
    aws = aws.db_proxy
  }
}


module "db_proxy" {
  source = "../modules/aws/db_proxy"
  count  = var.aws_db_proxy_enable ? 1 : 0
  # PROXY
  aws_aurora_proxy                            = var.aws_aurora_proxy
  aws_rds_db_proxy                            = var.aws_rds_db_proxy
  aws_db_proxy_name                           = var.aws_db_proxy_name != "" ? var.aws_db_proxy_name : lower(var.aws_resource_identifier)
  aws_db_proxy_database_id                    = var.aws_db_proxy_database_id
  aws_db_proxy_cluster                        = var.aws_db_proxy_cluster
  aws_db_proxy_secret_name                    = var.aws_db_proxy_secret_name
  aws_db_proxy_client_password_auth_type      = var.aws_db_proxy_client_password_auth_type
  aws_db_proxy_tls                            = var.aws_db_proxy_tls
  aws_db_proxy_security_group_name            = var.aws_db_proxy_security_group_name
  aws_db_proxy_database_security_group_allow  = var.aws_db_proxy_database_security_group_allow
  aws_db_proxy_allowed_security_group         = var.aws_db_proxy_allowed_security_group
  aws_db_proxy_allow_all_incoming             = var.aws_db_proxy_allow_all_incoming
  aws_db_proxy_cloudwatch_enable              = var.aws_db_proxy_cloudwatch_enable
  aws_db_proxy_cloudwatch_retention_days      = var.aws_db_proxy_cloudwatch_retention_days
  # Others
  #aws_ec2_security_group                      = var.aws_ec2_instance_create ? module.ec2[0].aws_security_group_ec2_sg_id : ""
  aws_selected_vpc_id                         = module.vpc.aws_selected_vpc_id
  aws_selected_subnets                        = module.vpc.aws_selected_vpc_subnets
  aws_resource_identifier                     = var.aws_resource_identifier
  aws_resource_identifier_supershort          = var.aws_resource_identifier_supershort
  incoming_random_string                      = null
  # Dependencies
  depends_on = [module.vpc,module.ec2]

  providers = {
    aws = aws.db_proxy
  }
}

module "proxy_dot_env" {
  source   = "../modules/commons/dot_env"
  filename = "proxy.env"
  content  = join("\n",[try(module.db_proxy_aurora[0].proxy_dot_env,""),try(module.db_proxy_rds[0].proxy_dot_env,""),try(module.db_proxy[0].proxy_dot_env,"")])
  depends_on = [ module.db_proxy_aurora,module.db_proxy_rds,module.db_proxy_rds ]
}

module "redis" {
  source = "../modules/aws/redis"
  count  = var.aws_redis_enable ? 1 : 0
  # Redis
  aws_redis_user                      = var.aws_redis_user
  aws_redis_user_access_string        = var.aws_redis_user_access_string
  aws_redis_user_group_name           = var.aws_redis_user_group_name
  aws_redis_security_group_name       = var.aws_redis_security_group_name
  aws_redis_ingress_allow_all         = var.aws_redis_ingress_allow_all
  aws_redis_allowed_security_groups   = var.aws_redis_allowed_security_groups
  aws_redis_subnets                   = var.aws_redis_subnets
  aws_redis_port                      = var.aws_redis_port
  aws_redis_at_rest_encryption        = var.aws_redis_at_rest_encryption
  aws_redis_in_transit_encryption     = var.aws_redis_in_transit_encryption
  aws_redis_replication_group_id      = var.aws_redis_replication_group_id
  aws_redis_node_type                 = var.aws_redis_node_type
  aws_redis_num_cache_clusters        = var.aws_redis_num_cache_clusters
  aws_redis_parameter_group_name      = var.aws_redis_parameter_group_name
  aws_redis_num_node_groups           = var.aws_redis_num_node_groups
  aws_redis_replicas_per_node_group   = var.aws_redis_replicas_per_node_group
  aws_redis_multi_az_enabled          = var.aws_redis_multi_az_enabled
  aws_redis_automatic_failover        = var.aws_redis_automatic_failover
  aws_redis_apply_immediately         = var.aws_redis_apply_immediately
  aws_redis_auto_minor_upgrade        = var.aws_redis_auto_minor_upgrade
  aws_redis_maintenance_window        = var.aws_redis_maintenance_window
  aws_redis_snapshot_window           = var.aws_redis_snapshot_window
  aws_redis_final_snapshot            = var.aws_redis_final_snapshot
  aws_redis_snapshot_restore_name     = var.aws_redis_snapshot_restore_name
  aws_redis_cloudwatch_enabled        = var.aws_redis_cloudwatch_enabled
  aws_redis_cloudwatch_lg_name        = var.aws_redis_cloudwatch_lg_name
  aws_redis_cloudwatch_log_format     = var.aws_redis_cloudwatch_log_format
  aws_redis_cloudwatch_log_type       = var.aws_redis_cloudwatch_log_type
  aws_redis_cloudwatch_retention_days = var.aws_redis_cloudwatch_retention_days
  aws_redis_single_line_url_secret    = var.aws_redis_single_line_url_secret
  # Others
  aws_selected_vpc_id                 = module.vpc.aws_selected_vpc_id
  aws_selected_subnets                = module.vpc.aws_selected_vpc_subnets
  aws_resource_identifier             = var.aws_resource_identifier
  aws_resource_identifier_supershort  = var.aws_resource_identifier_supershort

  # Dependencies
  depends_on = [module.vpc,module.ec2]
  providers = {
    aws = aws.redis
  }
}

module "vpc" {
  source = "../modules/aws/vpc"
  #count  = var.aws_ec2_instance_create || var.aws_efs_enable || var.aws_aurora_enable ? 1 : 0
  # VPC
  aws_vpc_create              = var.aws_vpc_create
  aws_vpc_id                  = var.aws_vpc_id 
  aws_vpc_subnet_id           = var.aws_vpc_subnet_id
  aws_vpc_cidr_block          = var.aws_vpc_cidr_block
  aws_vpc_name                = var.aws_vpc_name
  aws_vpc_public_subnets      = var.aws_vpc_public_subnets
  aws_vpc_private_subnets     = var.aws_vpc_private_subnets
  aws_vpc_availability_zones  = var.aws_vpc_availability_zones
  # Data inputs
  aws_ec2_instance_type       = var.aws_ec2_instance_type
  aws_ec2_security_group_name = var.aws_ec2_security_group_name
  # Others
  aws_resource_identifier     = var.aws_resource_identifier
  # NEW
  aws_vpc_enable_nat_gateway  = var.aws_vpc_enable_nat_gateway
  aws_vpc_single_nat_gateway  = var.aws_vpc_single_nat_gateway
  aws_vpc_external_nat_ip_ids = var.aws_vpc_external_nat_ip_ids
  # Toggle EKS flag to add tags to subnets
  aws_eks_create              = var.aws_eks_create
  providers = {
    aws = aws.vpc
  }
}

module "secretmanager_get" {
  source         = "../modules/aws/secretmanager_get"
  count          = var.env_aws_secret != "" ? 1 : 0
  env_aws_secret = var.env_aws_secret
}

module "aws_ecs" {
  source = "../modules/aws/ecs"
  count  = var.aws_ecs_enable ? 1 : 0
  # ECS
  aws_ecs_service_name               = var.aws_ecs_service_name 
  aws_ecs_cluster_name               = var.aws_ecs_cluster_name 
  aws_ecs_service_launch_type        = var.aws_ecs_service_launch_type
  aws_ecs_task_type                  = var.aws_ecs_task_type
  aws_ecs_task_name                  = var.aws_ecs_task_name
  aws_ecs_task_execution_role        = var.aws_ecs_task_execution_role
  aws_ecs_task_json_definition_file  = var.aws_ecs_task_json_definition_file
  aws_ecs_task_network_mode          = var.aws_ecs_task_network_mode
  aws_ecs_task_cpu                   = var.aws_ecs_task_cpu 
  aws_ecs_task_mem                   = var.aws_ecs_task_mem 
  aws_ecs_container_cpu              = var.aws_ecs_container_cpu 
  aws_ecs_container_mem              = var.aws_ecs_container_mem 
  aws_ecs_node_count                 = var.aws_ecs_node_count 
  aws_ecs_app_image                  = var.aws_ecs_app_image 
  aws_ecs_security_group_name        = var.aws_ecs_security_group_name 
  aws_ecs_assign_public_ip           = var.aws_ecs_assign_public_ip 
  aws_ecs_container_port             = var.aws_ecs_container_port 
  aws_ecs_lb_port                    = var.aws_ecs_lb_port
  aws_ecs_lb_redirect_enable         = var.aws_ecs_lb_redirect_enable
  aws_ecs_lb_container_path          = var.aws_ecs_lb_container_path
  aws_ecs_lb_ssl_policy              = var.aws_ecs_lb_ssl_policy
  aws_ecs_autoscaling_enable         = var.aws_ecs_autoscaling_enable
  aws_ecs_autoscaling_max_nodes      = var.aws_ecs_autoscaling_max_nodes
  aws_ecs_autoscaling_min_nodes      = var.aws_ecs_autoscaling_min_nodes
  aws_ecs_autoscaling_max_mem        = var.aws_ecs_autoscaling_max_mem
  aws_ecs_autoscaling_max_cpu        = var.aws_ecs_autoscaling_max_cpu
  aws_ecs_cloudwatch_enable          = var.aws_ecs_cloudwatch_enable
  aws_ecs_cloudwatch_lg_name         = var.aws_ecs_cloudwatch_enable ? ( var.aws_ecs_cloudwatch_lg_name != null ? var.aws_ecs_cloudwatch_lg_name : "${var.aws_resource_identifier}-ecs-logs" ) : null
  aws_ecs_cloudwatch_skip_destroy    = var.aws_ecs_cloudwatch_skip_destroy
  aws_ecs_cloudwatch_retention_days  = var.aws_ecs_cloudwatch_retention_days
  aws_region_current_name            = module.vpc.aws_region_current_name
  aws_selected_vpc_id                = module.vpc.aws_selected_vpc_id
  aws_selected_subnets               = module.vpc.aws_selected_vpc_subnets
  # Others
  aws_certificate_enabled            = var.aws_r53_enable_cert && length(module.aws_certificates) > 0 ? true : false
  aws_certificates_selected_arn      = var.aws_r53_enable_cert && var.aws_r53_domain_name != "" ? module.aws_certificates[0].selected_arn : ""
  aws_resource_identifier            = var.aws_resource_identifier
  aws_resource_identifier_supershort = var.aws_resource_identifier_supershort
  app_repo_name                      = var.app_repo_name
  # Dependencies
  depends_on = [ module.aws_certificates ]
  providers = {
    aws = aws.ecs
  }
}

module "aws_route53_ecs" {
  source = "../modules/aws/route53"
  count  = var.aws_ecs_enable && var.aws_r53_enable && var.aws_r53_domain_name != "" ? 1 : 0
  # R53 values
  aws_r53_domain_name           = var.aws_r53_domain_name
  aws_r53_sub_domain_name       = var.aws_r53_sub_domain_name
  aws_r53_root_domain_deploy    = var.aws_r53_root_domain_deploy
  aws_r53_enable_cert           = var.aws_r53_enable_cert
  # ELB
  aws_elb_dns_name              = try(module.aws_ecs[0].load_balancer_dns,"")
  aws_elb_zone_id               = try(module.aws_ecs[0].load_balancer_zone_id,"")
  # Certs
  aws_certificates_selected_arn = var.aws_r53_enable_cert && var.aws_r53_domain_name != "" ? module.aws_certificates[0].selected_arn : ""
  # Others
  fqdn_provided                 = local.fqdn_provided
  depends_on = [ module.aws_certificates,module.aws_ecs ]
  providers = {
    aws = aws.r53
  }
}

#module "aws_ecr" {
#  source = "../modules/aws/ecr"
#  count  = var.aws_ecr_repo_create ? 1 : 0
#  # ECR
#  aws_ecr_repo_type                         = var.aws_ecr_repo_type
#  aws_ecr_repo_name                         = var.aws_ecr_repo_name
#  aws_ecr_repo_mutable                      = var.aws_ecr_repo_mutable
#  aws_ecr_repo_encryption_type              = var.aws_ecr_repo_encryption_type
#  aws_ecr_repo_encryption_key_arn           = var.aws_ecr_repo_encryption_key_arn
#  aws_ecr_repo_force_destroy                = var.aws_ecr_repo_force_destroy
#  aws_ecr_repo_image_scan                   = var.aws_ecr_repo_image_scan
#  aws_ecr_registry_scan_rule                = var.aws_ecr_registry_scan_rule
#  aws_ecr_registry_pull_through_cache_rules = var.aws_ecr_registry_pull_through_cache_rules
#  aws_ecr_registry_scan_config              = var.aws_ecr_registry_scan_config
#  aws_ecr_registry_replication_rules_input  = var.aws_ecr_registry_replication_rules_input
#  aws_ecr_repo_policy_attach                = var.aws_ecr_repo_policy_attach
#  aws_ecr_repo_policy_create                = var.aws_ecr_repo_policy_create
#  aws_ecr_repo_policy_input                 = var.aws_ecr_repo_policy_input
#  aws_ecr_repo_read_arn                     = var.aws_ecr_repo_read_arn
#  aws_ecr_repo_write_arn                    = var.aws_ecr_repo_write_arn
#  aws_ecr_repo_read_arn_lambda              = var.aws_ecr_repo_read_arn_lambda
#  aws_ecr_lifecycle_policy_input            = var.aws_ecr_lifecycle_policy_input
#  aws_ecr_public_repo_catalog               = var.aws_ecr_public_repo_catalog
#  aws_ecr_registry_policy_input             = var.aws_ecr_registry_policy_input
#  # Others
#  aws_resource_identifier                   = var.aws_resource_identifier
#
#  providers = {
#    aws = aws.ecr
#  }
#}

module "eks" {
  source = "../modules/aws/eks"
  count  = var.aws_eks_create ? 1 : 0
  # EKS
  #aws_eks_create                     = var.aws_eks_create
  aws_eks_security_group_name_cluster = var.aws_eks_security_group_name_cluster
  aws_eks_security_group_name_node = var.aws_eks_security_group_name_node
  aws_eks_environment                = var.aws_eks_environment
  aws_eks_management_cidr            = var.aws_eks_management_cidr
  aws_eks_allowed_ports              = var.aws_eks_allowed_ports
  aws_eks_allowed_ports_cidr         = var.aws_eks_allowed_ports_cidr
  aws_eks_cluster_name               = var.aws_eks_cluster_name
  aws_eks_cluster_admin_role_arn     = var.aws_eks_cluster_admin_role_arn
  aws_eks_cluster_log_types          = var.aws_eks_cluster_log_types
  aws_eks_cluster_log_retention_days = var.aws_eks_cluster_log_retention_days
  aws_eks_cluster_log_skip_destroy  = var.aws_eks_cluster_log_skip_destroy
  aws_eks_cluster_version            = var.aws_eks_cluster_version
  aws_eks_instance_type              = var.aws_eks_instance_type
  aws_eks_instance_ami_id            = var.aws_eks_instance_ami_id
  aws_eks_instance_user_data_file    = var.aws_eks_instance_user_data_file
  aws_eks_ec2_key_pair               = var.aws_eks_ec2_key_pair
  aws_eks_store_keypair_sm           = var.aws_eks_store_keypair_sm
  aws_eks_desired_capacity           = var.aws_eks_desired_capacity
  aws_eks_max_size                   = var.aws_eks_max_size
  aws_eks_min_size                   = var.aws_eks_min_size
  # Others
  aws_selected_vpc_id                = module.vpc.aws_selected_vpc_id
  aws_resource_identifier            = var.aws_resource_identifier
  providers = {
    aws = aws.eks
    kubernetes = kubernetes.eks
  }
  depends_on = [ module.vpc ]
}

module "ansible" {
  source = "../modules/aws/ansible"
  count  = var.ansible_skip ? 0 : var.aws_ec2_instance_create ? 1 : 0
  aws_ec2_instance_ip              = var.ansible_ssh_to_private_ip ? module.ec2[0].instance_private_ip : ( module.ec2[0].instance_public_ip != "" ? module.ec2[0].instance_public_ip : module.ec2[0].instance_private_ip )
  ansible_start_docker_timeout     = var.ansible_start_docker_timeout
  aws_efs_enable                   = var.aws_efs_enable
  app_repo_name                    = var.app_repo_name
  app_install_root                 = var.app_install_root
  aws_resource_identifier          = var.aws_resource_identifier
  docker_remove_orphans            = var.docker_remove_orphans
  # Cloudwatch
  docker_cloudwatch_enable         = var.docker_cloudwatch_enable
  docker_cloudwatch_lg_name        = var.docker_cloudwatch_lg_name != "" ? var.docker_cloudwatch_lg_name : "${var.aws_resource_identifier}-docker-logs"
  docker_cloudwatch_skip_destroy   = var.docker_cloudwatch_skip_destroy
  docker_cloudwatch_retention_days = var.docker_cloudwatch_retention_days
  aws_region_current_name          = module.vpc.aws_region_current_name
  aws_efs_ec2_mount_point          = var.aws_efs_ec2_mount_point
  aws_efs_mount_target             = var.aws_efs_mount_target
  docker_efs_mount_target          = var.docker_efs_mount_target
  aws_efs_fs_id                    = var.aws_efs_enable ? local.create_efs ? module.efs[0].aws_efs_fs_id : var.aws_efs_fs_id : null
  # Data inputs
  private_key_filename             = module.ec2[0].private_key_filename
  # Dependencies
  depends_on = [module.ec2]
}

locals {
  aws_tags = {
    OperationsRepo            = "bitovi/github-actions-commons/operations/${var.ops_repo_environment}"
    AWSResourceIdentifier     = "${var.aws_resource_identifier}"
    GitHubOrgName             = "${var.app_org_name}"
    GitHubRepoName            = "${var.app_repo_name}"
    GitHubBranchName          = "${var.app_branch_name}"
    GitHubAction              = "bitovi/github-actions-commons"
    OperationsRepoEnvironment = "${var.ops_repo_environment}"
    Created_with              = "Bitovi-BitOps"
  }
  default_tags = merge(local.aws_tags, jsondecode(var.aws_additional_tags))
  # Module tagging
  ec2_tags      = merge(local.default_tags,jsondecode(var.aws_ec2_additional_tags))
  r53_tags      = merge(local.default_tags,jsondecode(var.aws_r53_additional_tags))
  elb_tags      = merge(local.default_tags,jsondecode(var.aws_elb_additional_tags))
  efs_tags      = merge(local.default_tags,jsondecode(var.aws_efs_additional_tags))
  vpc_tags      = var.aws_eks_create ? local.vpc_eks_tags : merge(local.default_tags,jsondecode(var.aws_vpc_additional_tags))
  vpc_eks_tags  = merge(local.default_tags,jsondecode(var.aws_vpc_additional_tags),local.eks_vpc_tags)
  eks_tags      = merge(local.default_tags,jsondecode(var.aws_eks_additional_tags))
  rds_tags      = merge(local.default_tags,jsondecode(var.aws_rds_db_additional_tags))
  ecs_tags      = merge(local.default_tags,jsondecode(var.aws_ecs_additional_tags))
  aurora_tags   = merge(local.default_tags,jsondecode(var.aws_aurora_additional_tags))
  ecr_tags      = merge(local.default_tags,jsondecode(var.aws_ecr_additional_tags))
  db_proxy_tags = merge(local.default_tags,jsondecode(var.aws_db_proxy_additional_tags))
  redis_tags    = merge(local.default_tags,jsondecode(var.aws_redis_additional_tags))

  eks_vpc_tags = {
    // This is needed for k8s to use VPC resources
    "kubernetes.io/cluster/${var.aws_eks_cluster_name}" = "shared"
    "environment"                                       = var.aws_eks_environment
  }

  fqdn_provided = (
    (var.aws_r53_domain_name != "") ?
    (var.aws_r53_sub_domain_name != "" ?
      true :
      var.aws_r53_root_domain_deploy ? true : false
    ) :
    false
  )
  create_efs           = var.aws_efs_create == true ? true : (var.aws_efs_create_ha == true ? true : false)
  ec2_public_endpoint  = var.aws_ec2_instance_create ? ( module.ec2[0].instance_public_dns  != null ? module.ec2[0].instance_public_dns  : module.ec2[0].instance_public_ip  ) : null
  ec2_private_endpoint = var.aws_ec2_instance_create ? ( module.ec2[0].instance_private_dns != null ? module.ec2[0].instance_private_dns : module.ec2[0].instance_private_ip ) : null
  ec2_endpoint         = var.aws_ec2_instance_create ? ( local.ec2_public_endpoint != null ? "http://${local.ec2_public_endpoint}" : "http://${local.ec2_private_endpoint}" ) : null
  elb_url              = try(module.aws_elb[0].aws_elb_dns_name,null ) != null ? "http://${module.aws_elb[0].aws_elb_dns_name}" : null
}

# VPC
output "aws_vpc_id" {
  value = module.vpc.aws_selected_vpc_id
}

# EC2
output "instance_public_dns" {
  description = "Public DNS address of the EC2 instance"
  value       = try(module.ec2[0].instance_public_dns,null)
}

output "instance_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = try(module.ec2[0].instance_public_ip,null)
}

output "instance_private_dns" {
  description = "Public DNS address of the EC2 instance"
  value       = try(module.ec2[0].instance_private_dns,null)
}

output "instance_private_ip" {
  description = "Private IP address of the EC2 instance"
  value       = try(module.ec2[0].instance_private_ip,null)
}

output "instance_endpoint" {
  description = "Will print the best EC2 option, from public dns to private ip"
  value       = local.ec2_endpoint
}

output "ec2_sg_id" {
  description = "SG ID for the EC2 instance"
  value       = try(module.ec2[0].aws_security_group_ec2_sg_id,null)
}

output "aws_elb_dns_name" {
  description = "Public DNS address of the LB"
  value       = try(module.aws_elb[0].aws_elb_dns_name,null)
}

output "application_public_dns" {
  description = "Public DNS address for the application or load balancer public DNS"
  value       = try(module.aws_route53[0].vm_url,null)
}

output "vm_url" {
  value = try(module.aws_route53[0].vm_url,local.elb_url)
}

# EFS
output "aws_efs_fs_id" {
  value = try(module.efs[0].aws_efs_fs_id,null)
}
output "aws_efs_replica_fs_id" {
  value = try(module.efs[0].aws_efs_replica_fs_id,null)
}
output "aws_efs_sg_id" {
  value = try(module.efs[0].aws_efs_sg_id,null)
}

# Aurora
output "aurora_db_endpoint" {
  value = try(module.aurora_rds[0].aurora_db_endpoint,null)
}
output "aurora_db_secret_details_name" {
  value = try(module.aurora_rds[0].aurora_secret_name,null)
}
output "aurora_db_sg_id" {
  value = try(module.aurora_rds[0].aurora_sg_id,null)
}

# Aurora Proxy 
output "aurora_proxy_endpoint" {
  value = try(module.db_proxy_aurora[0].db_proxy_endpoint,null)
}
output "aurora_proxy_secret_name" {
  value = try(module.db_proxy_aurora[0].db_proxy_secret_name,null)
}
output "aurora_proxy_sg_id" {
  value = try(module.db_proxy_aurora[0].db_proxy_sg_id,null)
}

# RDS
output "db_endpoint" {
  value = try(module.rds[0].db_endpoint,null)
}
output "db_secret_details_name" {
  value = try(module.rds[0].db_secret_name,null)
}
output "db_sg_id" {
  value = try(module.rds[0].db_sg_id,null)
}

# RDS Proxy
output "db_proxy_rds_endpoint" {
  value = try(module.db_proxy_rds[0].db_proxy_endpoint,null)
}
output "db_proxy_secret_name_rds" {
  value = try(module.db_proxy_rds[0].db_proxy_secret_name,null)
}
output "db_proxy_sg_id_rds" {
  value = try(module.db_proxy_rds[0].db_proxy_sg_id,null)
}

# Proxy
output "db_proxy_endpoint" {
  value = try(module.db_proxy[0].db_proxy_endpoint,null)
}
output "db_proxy_secret_name" {
  value = try(module.db_proxy[0].db_proxy_secret_name,null)
}
output "db_proxy_sg_id" {
  value = try(module.db_proxy[0].db_proxy_sg_id,null)
}

# ECS
output "ecs_dns_record" {
  value = try(module.aws_route53_ecs[0].vm_url,null)
}

output "ecs_load_balancer_dns" {
  value = try(module.aws_ecs[0].load_balancer_dns,null)
}

output "ecs_sg_id" {
  value = try(module.aws_ecs[0].ecs_sg.id,null)
}

output "ecs_lb_sg_id" {
  value = try(module.aws_ecs[0].ecs_lb_sg.id,null)
}

# Redis
output "redis_secret_name" {
  value = try(module.redis[0].redis_secret_name,null)
}

output "redis_endpoint" {
  value = try(module.redis[0].redis_endpoint,null)
}

output "redis_connection_string_secret" {
  value = try(module.redis[0].redis_connection_string_secret,null)
}

output "redis_sg_id" {
  value = try(module.redis[0].redis_sg_id,null)
}

# EKS
output "eks_cluster_name" {
  value = try(module.eks[0].aws_eks_cluster_name,null)
}

output "eks_cluster_role_arn" {
  value = try(module.eks[0].aws_eks_cluster_role_arn,null)
}
