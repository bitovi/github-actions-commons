resource "aws_security_group" "rds_db_security_group" {
  name        = var.aws_rds_db_security_group_name != null ? var.aws_rds_db_security_group_name : "SG for ${var.aws_resource_identifier} - RDS"
  description = "SG for ${var.aws_resource_identifier} - RDS"
  vpc_id      = var.aws_selected_vpc_id
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "${var.aws_resource_identifier}-rds"
  }
}

resource "aws_security_group_rule" "ingress_rds" {
  count             = var.aws_rds_db_ingress_allow_all ? 1 : 0
  type              = "ingress"
  description       = "${var.aws_resource_identifier} - RDS Port"
  from_port         = tonumber(aws_db_instance.default.port)
  to_port           = tonumber(aws_db_instance.default.port)
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.rds_db_security_group.id
}

locals {
  aws_rds_db_allowed_security_groups = var.aws_rds_db_allowed_security_groups != null ? [for n in split(",", var.aws_rds_db_allowed_security_groups) : n] : []
}

resource "aws_security_group_rule" "ingress_rds_extras" {
  count                    = length(local.aws_rds_db_allowed_security_groups)
  type                     = "ingress"
  description              = "${var.aws_resource_identifier} - RDS ingress extra SG"
  from_port                = tonumber(aws_db_instance.default.port)
  to_port                  = tonumber(aws_db_instance.default.port)
  protocol                 = "tcp"
  source_security_group_id = local.aws_rds_db_allowed_security_groups[count.index]
  security_group_id        = aws_security_group.rds_db_security_group.id
}

locals {
  aws_rds_db_subnets = var.aws_rds_db_subnets != null ? [for n in split(",", var.aws_rds_db_subnets) : (n)] : var.aws_subnets_vpc_subnets_ids
  skip_snap          = length(var.aws_rds_db_final_snapshot) != "" ? false : true
}

resource "aws_db_subnet_group" "selected" {
  name       = "${var.aws_resource_identifier}-rds"
  subnet_ids = local.aws_rds_db_subnets
  tags = {
    Name = "${var.aws_resource_identifier}-rds"
  }
}

resource "aws_db_instance" "default" {
  identifier                            = var.aws_rds_db_identifier
  engine                                = var.aws_rds_db_engine
  engine_version                        = var.aws_rds_db_engine_version
  ca_cert_identifier                    = var.aws_rds_db_ca_cert_identifier
  db_subnet_group_name                  = aws_db_subnet_group.selected.name
  db_name                               = var.aws_rds_db_name != null ? var.aws_rds_db_name : null
  port                                  = var.aws_rds_db_port != null ? tonumber(var.aws_rds_db_port) : null
  allocated_storage                     = tonumber(var.aws_rds_db_allocated_storage)
  max_allocated_storage                 = tonumber(var.aws_rds_db_max_allocated_storage)
  storage_encrypted                     = var.aws_rds_db_storage_encrypted
  storage_type                          = var.aws_rds_db_storage_type
  kms_key_id                            = var.aws_rds_db_kms_key_id
  instance_class                        = var.aws_rds_db_instance_class
  username                              = var.aws_rds_db_user != null ? var.aws_rds_db_user : "dbuser"
  password                              = random_password.rds.result
  skip_final_snapshot                   = var.aws_rds_db_final_snapshot != "" ? false : true
  final_snapshot_identifier             = var.aws_rds_db_final_snapshot != "" ? var.aws_rds_db_final_snapshot : null
  snapshot_identifier                   = var.aws_rds_db_restore_snapshot_identifier
  publicly_accessible                   = var.aws_rds_db_publicly_accessible
  enabled_cloudwatch_logs_exports       = [var.aws_rds_db_cloudwatch_logs_exports]
  vpc_security_group_ids                = [aws_security_group.rds_db_security_group.id]
  multi_az                              = var.aws_rds_db_multi_az
  maintenance_window                    = var.aws_rds_db_maintenance_window
  apply_immediately                     = var.aws_rds_db_apply_immediately
  performance_insights_enabled          = var.aws_rds_db_performance_insights_enable
  performance_insights_retention_period = var.aws_rds_db_performance_insights_enable ? var.aws_rds_db_performance_insights_retention : null
  performance_insights_kms_key_id       = var.aws_rds_db_performance_insights_enable ? var.aws_rds_db_performance_insights_kms_key_id : null
  # Updgrades
  monitoring_interval         = var.aws_rds_db_monitoring_interval
  monitoring_role_arn         = var.aws_rds_db_monitoring_interval > 0 ? var.aws_rds_db_monitoring_role_arn != "" ? var.aws_rds_db_monitoring_role_arn : aws_iam_role.rds_enhanced_monitoring[0].arn : null
  database_insights_mode      = var.aws_rds_db_insights_mode
  allow_major_version_upgrade = var.aws_rds_db_allow_major_version_upgrade
  auto_minor_version_upgrade  = var.aws_rds_db_auto_minor_version_upgrade
  backup_retention_period     = var.aws_rds_db_backup_retention_period
  backup_window               = var.aws_rds_db_backup_window
  copy_tags_to_snapshot       = var.aws_rds_db_copy_tags_to_snapshot
  tags = {
    Name = "${var.aws_resource_identifier}-rds"
  }
}

resource "aws_iam_role" "rds_enhanced_monitoring" {
  count = var.aws_rds_db_monitoring_role_arn != "" ? 0 : var.aws_rds_db_monitoring_interval > 0 ? 1 : 0
  name  = "${var.aws_resource_identifier}-rds"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "monitoring.rds.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "rds_enhanced_monitoring_attach" {
  count      = var.aws_rds_db_monitoring_role_arn != "" ? 0 : var.aws_rds_db_monitoring_interval > 0 ? 1 : 0
  role       = aws_iam_role.rds_enhanced_monitoring[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

// Creates a secret manager secret for the databse credentials
resource "aws_secretsmanager_secret" "rds_database_credentials" {
  name = "${var.aws_resource_identifier_supershort}-rdsdb-pub-${random_string.random_sm.result}"
}

# Username and Password are repeated for compatibility with proxy and legacy code.
resource "aws_secretsmanager_secret_version" "database_credentials_sm_secret_version_dev" {
  secret_id = aws_secretsmanager_secret.rds_database_credentials.id
  secret_string = jsonencode({
    username          = sensitive(aws_db_instance.default.username)
    password          = sensitive(aws_db_instance.default.password)
    host              = sensitive(aws_db_instance.default.address)
    port              = sensitive(aws_db_instance.default.port)
    database          = sensitive(aws_db_instance.default.db_name)
    engine            = sensitive(aws_db_instance.default.engine)
    engine_version    = sensitive(aws_db_instance.default.engine_version)
    DB_USER           = sensitive(aws_db_instance.default.username)
    DB_USERNAME       = sensitive(aws_db_instance.default.username)
    DB_PASSWORD       = sensitive(aws_db_instance.default.password)
    DB_HOST           = sensitive(aws_db_instance.default.address)
    DB_PORT           = sensitive(aws_db_instance.default.port)
    DB_NAME           = sensitive(aws_db_instance.default.db_name)
    DB_ENGINE         = sensitive(aws_db_instance.default.engine)
    DB_ENGINE_VERSION = sensitive(aws_db_instance.default.engine_version)
  })
}

resource "random_password" "rds" {
  length  = 25
  special = false
  lifecycle {
    ignore_changes = all
  }
}

resource "random_string" "random_sm" {
  length  = 5
  lower   = true
  special = false
  numeric = false
}

data "aws_vpc" "selected" {
  count = var.aws_selected_vpc_id != null ? 1 : 0
  id    = var.aws_selected_vpc_id
}

output "db_endpoint" {
  value = aws_db_instance.default.endpoint
}

output "db_secret_name" {
  value = aws_secretsmanager_secret.rds_database_credentials.name
}

output "db_id" {
  value = aws_db_instance.default.id
}

output "random_string" {
  value = random_string.random_sm.result
}

output "rds_sg_id" {
  value = aws_security_group.rds_db_security_group.id
}

output "db_port" {
  value = aws_db_instance.default.port
}