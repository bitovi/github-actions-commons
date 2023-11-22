resource "aws_security_group" "aurora_security_group" {
  name        = var.aws_aurora_security_group_name != "" ? var.aws_aurora_security_group_name : "SG for ${var.aws_resource_identifier} - Aurora"
  description = "SG for ${var.aws_resource_identifier} - Aurora"
  vpc_id      = var.aws_selected_vpc_id
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "${var.aws_resource_identifier}-aurora"
  }
}

resource "aws_security_group_rule" "ingress_aurora" {
  count             = var.aws_aurora_ingress_allow_all ? 1 : 0
  type              = "ingress"
  description       = "${var.aws_resource_identifier} - Aurora Port"
  from_port         = tonumber(var.aws_aurora_database_port)
  to_port           = tonumber(var.aws_aurora_database_port)
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.aurora_security_group.id
}

locals {
  aws_aurora_allowed_security_groups = var.aws_aurora_allowed_security_groups != null ? [for n in split(",", var.aws_aurora_allowed_security_groups) : n] : []
}

resource "aws_security_group_rule" "ingress_aurora_extras" {
  count                    = length(local.aws_aurora_allowed_security_groups)
  type                     = "ingress"
  description              = "${var.aws_resource_identifier} - RDS ingress extra SG"
  from_port                = tonumber(aws_rds_cluster.aurora.port)
  to_port                  = tonumber(aws_rds_cluster.aurora.port)
  protocol                 = "tcp"
  source_security_group_id = local.aws_aurora_allowed_security_groups[count.index]
  security_group_id        = aws_security_group.aurora_security_group.id
}

locals {
  aws_aurora_subnets = var.aws_aurora_subnets  != "" ? [for n in split(",", var.aws_aurora_subnets)  : (n)] :  var.aws_subnets_vpc_subnets_ids
  skip_snap = length(var.aws_aurora_database_final_snapshot) != "" ? false : true
  aws_aurora_cloudwatch_log_type = var.aws_aurora_cloudwatch_log_type != "" ? [for n in split(",", var.aws_aurora_cloudwatch_log_type) : n] : local.log_types
  log_types = strcontains(var.aws_aurora_engine, "postgres") ? ["postgresql"] : strcontains(var.aws_aurora_engine, "mysql") ? ["audit","error","general","slowquery"] : []
}

resource "aws_db_subnet_group" "selected" {
  name       = "${var.aws_resource_identifier}-rds"
  subnet_ids = local.aws_aurora_subnets
  tags = {
    Name = "${var.aws_resource_identifier}-rds"
  }
}

resource "aws_rds_cluster" "aurora" {
  # DB Parameters
  cluster_identifier                  = var.aws_aurora_cluster_name != "" ? var.aws_aurora_cluster_name : var.aws_resource_identifier
  engine                              = var.aws_aurora_engine
  engine_version                      = var.aws_aurora_engine_version
  engine_mode                         = var.aws_aurora_engine_mode != "" ? var.aws_aurora_engine_mode : null
  availability_zones                  = var.aws_aurora_availability_zones != "" ? [var.aws_aurora_availability_zones] : []
  apply_immediately                   = var.aws_aurora_cluster_apply_immediately
  # Storage
  allocated_storage                   = try(tonumber(var.aws_aurora_allocated_storage),null)
  storage_encrypted                   = var.aws_aurora_storage_encrypted
  kms_key_id                          = var.aws_aurora_kms_key_id 
  storage_type                        = var.aws_aurora_storage_type
  iops                                = try(tonumber(var.aws_aurora_storage_iops),null)
  # DB Details
  database_name                       = var.aws_aurora_database_name
  master_username                     = var.aws_aurora_master_username
  master_password                     = sensitive(random_password.rds.result)
  iam_database_authentication_enabled = var.aws_aurora_iam_auth_enabled
  iam_roles                           = var.aws_aurora_iam_roles != "" ? [var.aws_aurora_iam_roles] : []
  db_cluster_parameter_group_name     = var.aws_resource_identifier
  # Backup & Maint
  enabled_cloudwatch_logs_exports     = var.aws_aurora_cloudwatch_enable ? local.aws_aurora_cloudwatch_log_type : []
  backtrack_window                    = var.aws_aurora_backtrack_window 
  backup_retention_period             = var.aws_aurora_backup_retention_period
  preferred_backup_window             = var.aws_aurora_backup_window
  preferred_maintenance_window        = var.aws_aurora_maintenance_window
  deletion_protection                 = var.aws_aurora_deletion_protection
  delete_automated_backups            = var.aws_aurora_delete_auto_backups
  final_snapshot_identifier           = var.aws_aurora_database_final_snapshot != "" ? var.aws_aurora_database_final_snapshot : null
  skip_final_snapshot                 = var.aws_aurora_database_final_snapshot != "" ? false : true
  snapshot_identifier                 = var.aws_aurora_restore_snapshot_id
  # Net
  db_subnet_group_name                = aws_db_subnet_group.selected.id
  db_cluster_instance_class           = var.aws_aurora_cluster_db_instance_class
  vpc_security_group_ids              = [aws_security_group.aurora_security_group.id]
  port                                = var.aws_aurora_database_port

  dynamic "restore_to_point_in_time" {
     for_each = length(var.aws_aurora_restore_to_point_in_time) > 0 ? [var.aws_aurora_restore_to_point_in_time] : []

     content {
       restore_to_time            = try(aws_aurora_restore_to_point_in_time.value.restore_to_time, null)
       restore_type               = try(aws_aurora_restore_to_point_in_time.value.restore_type, null)
       source_cluster_identifier  = aws_aurora_restore_to_point_in_time.value.source_cluster_identifier
       use_latest_restorable_time = try(aws_aurora_restore_to_point_in_time.value.use_latest_restorable_time, null)
     }
  }

  lifecycle {
    ignore_changes = [
      # See https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/rds_cluster#replication_source_identifier
      # Since this is used either in read-replica clusters or global clusters, this should be acceptable to specify
      replication_source_identifier,
      # See docs here https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/rds_global_cluster#new-global-cluster-from-existing-db-cluster
      global_cluster_identifier,
      snapshot_identifier,
      availability_zones
    ]
  }
}

resource "aws_rds_cluster_instance" "cluster_instance" {
  count                        = tonumber(var.aws_aurora_db_instances_count)
  identifier                   = "${aws_rds_cluster.aurora.cluster_identifier}-${count.index}"
  cluster_identifier           = aws_rds_cluster.aurora.id
  instance_class               = var.aws_aurora_db_instance_class
  publicly_accessible          = var.aws_aurora_db_publicly_accessible
  db_subnet_group_name         = aws_db_subnet_group.selected.id
  engine                       = aws_rds_cluster.aurora.engine
  engine_version               = aws_rds_cluster.aurora.engine_version
  apply_immediately            = var.aws_aurora_db_apply_immediately
  ca_cert_identifier           = var.aws_aurora_db_ca_cert_identifier
  preferred_maintenance_window = var.aws_aurora_db_maintenance_window
}

resource "aws_rds_cluster_parameter_group" "mysql" {
  count       = strcontains(var.aws_aurora_engine, "mysql") ? 1 : 0
  name        = var.aws_resource_identifier
  description = "${var.aws_resource_identifier} cluster parameter group"
  family      = var.aws_aurora_database_group_family != "" ? var.aws_aurora_database_group_family : "${var.aws_aurora_engine}8.0"

  parameter {
      name         = "require_secure_transport"
      value        = "ON"
      apply_method = "immediate"
  }

  #lifecycle {
  #  create_before_destroy = true
  #}
}

resource "aws_rds_cluster_parameter_group" "postgresql" {
  count       = strcontains(var.aws_aurora_engine, "postgres")? 1 : 0
  name        = var.aws_resource_identifier
  description = "${var.aws_resource_identifier} cluster parameter group"
  family      = var.aws_aurora_database_group_family != "" ? var.aws_aurora_database_group_family : "${var.aws_aurora_engine}15"

  parameter {
    name         = "log_min_duration_statement"
    value        = 4000
    apply_method = "immediate"
  }

  parameter {
    name         = "rds.force_ssl"
    value        = 1
    apply_method = "immediate"
  }

  #lifecycle {
  #  create_before_destroy = true
  #}
}

resource "random_password" "rds" {
  length = 10
  special = false
}

// Creates a secret manager secret for the databse credentials
resource "aws_secretsmanager_secret" "aurora_database_credentials" {
  name   = "${var.aws_resource_identifier_supershort}-aurora-${random_string.random_sm.result}"
}

# Username and Password are repeated for compatibility with proxy and legacy code.
resource "aws_secretsmanager_secret_version" "database_credentials_sm_secret_version_dev" {
  secret_id = aws_secretsmanager_secret.aurora_database_credentials.id
  secret_string = jsonencode({
   database_password = sensitive(aws_rds_cluster.aurora.master_password)
   username          = sensitive(aws_rds_cluster.aurora.master_username)
   password          = sensitive(aws_rds_cluster.aurora.master_password)
   host              = sensitive(aws_rds_cluster.aurora.endpoint)
   port              = sensitive(aws_rds_cluster.aurora.port)
   database          = sensitive(aws_rds_cluster.aurora.database_name == null ? "" : aws_rds_cluster.aurora.database_name)
   engine            = sensitive(local.dba_engine)
   engine_version    = sensitive(aws_rds_cluster.aurora.engine_version_actual)
   DB_USER           = sensitive(aws_rds_cluster.aurora.master_username)
   DB_USERNAME       = sensitive(aws_rds_cluster.aurora.master_username)
   DB_PASSWORD       = sensitive(aws_rds_cluster.aurora.master_password)
   DB_HOST           = sensitive(aws_rds_cluster.aurora.endpoint)
   DB_PORT           = sensitive(aws_rds_cluster.aurora.port)
   DB_NAME           = sensitive(aws_rds_cluster.aurora.database_name == null ? "" : aws_rds_cluster.aurora.database_name)
   DB_ENGINE         = sensitive(local.dba_engine)
   DB_ENGINE_VERSION = sensitive(aws_rds_cluster.aurora.engine_version_actual)
  })
}

resource "random_string" "random_sm" {
  length    = 5
  lower     = true
  special   = false
  numeric   = false
}

resource "aws_cloudwatch_log_group" "logs" {
  name              = "/aws/rds/cluster/${aws_rds_cluster.aurora.cluster_identifier}/"
  retention_in_days = var.aws_aurora_cloudwatch_retention_days
}

### All of this added to handle snapshots
resource "aws_db_cluster_snapshot" "db_snapshot" {
  count                          = var.aws_aurora_snapshot_name != "" ? ( var.aws_aurora_snapshot_overwrite ? 0 : 1 ) : 0 
  db_cluster_identifier          = aws_rds_cluster.aurora.cluster_identifier
  db_cluster_snapshot_identifier = var.aws_aurora_snapshot_name
  lifecycle {
    ignore_changes = all
  }
}

resource "aws_db_cluster_snapshot" "overwrite_db_snapshot" {
  count                          = var.aws_aurora_snapshot_name != "" ? ( var.aws_aurora_snapshot_overwrite ? 1 : 0 ) : 0
  db_cluster_identifier          = aws_rds_cluster.aurora.cluster_identifier
  db_cluster_snapshot_identifier = var.aws_aurora_snapshot_name
  lifecycle {
    create_before_destroy = true
  }
}

data "aws_vpc" "selected" {
  count = var.aws_selected_vpc_id != null ? 1 : 0
  id    = var.aws_selected_vpc_id
}

output "aurora_db_id" {
  value = aws_rds_cluster.aurora.cluster_identifier
}

output "aurora_secret_name" {
  value = aws_secretsmanager_secret.aurora_database_credentials.name
}

output "aurora_db_endpoint" {
  value = aws_rds_cluster.aurora.endpoint
}

output "random_string" {
  value = random_string.random_sm.result
}