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
  type              = "ingress"
  description       = "${var.aws_resource_identifier} - Aurora Port"
  from_port         = tonumber(var.aws_aurora_database_port)
  to_port           = tonumber(var.aws_aurora_database_port)
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.aurora_security_group.id
}

locals {
  aws_aurora_subnets = var.aws_aurora_subnets != "" ? [for n in split(",", var.aws_aurora_subnets) : (n)] : []
}

module "aurora_cluster" {
  source         = "terraform-aws-modules/rds-aurora/aws"
  version        = "v7.7.1"
  name           = var.aws_aurora_cluster_name != "" ? var.aws_aurora_cluster_name : var.aws_resource_identifier

  engine         = var.aws_aurora_engine
  engine_version = var.aws_aurora_engine_version
  instance_class = var.aws_aurora_instance_class
  instances = {
    1 = {
      instance_class = var.aws_aurora_instance_class
    }
  }

  vpc_id                 = var.aws_selected_vpc_id
  subnets                = length(local.aws_aurora_subnets) != 0 ? local.aws_aurora_subnets : var.aws_subnets_vpc_subnets_ids
  
  allowed_security_groups = [var.aws_allowed_sg_id]
  allowed_cidr_blocks     = [data.aws_vpc.selected[0].cidr_block]

  database_name          = var.aws_aurora_database_name
  port                   = var.aws_aurora_database_port
  deletion_protection    = var.aws_aurora_database_protection
  storage_encrypted      = true
  monitoring_interval    = 60
  create_db_subnet_group = true
  db_subnet_group_name   = "${var.aws_resource_identifier}-aurora"
  create_security_group  = false
  vpc_security_group_ids = [aws_security_group.aurora_security_group.id]

  # TODO: take advantage of iam database auth
  iam_database_authentication_enabled    = true
  master_password                        = random_password.rds.result
  create_random_password                 = false
  apply_immediately                      = true
  skip_final_snapshot                    = var.aws_aurora_database_final_snapshot == "" ? true : false
  final_snapshot_identifier_prefix       = var.aws_aurora_database_final_snapshot
  snapshot_identifier                    = var.aws_aurora_restore_snapshot
  create_db_cluster_parameter_group      = true
  db_cluster_parameter_group_name        = var.aws_resource_identifier

  db_cluster_parameter_group_family      = var.aws_aurora_database_group_family
  db_cluster_parameter_group_description = "${var.aws_resource_identifier}  cluster parameter group"
  db_cluster_parameter_group_parameters = var.aws_aurora_engine == "aurora-postgresql" ? [
    {
      name         = "log_min_duration_statement"
      value        = 4000
      apply_method = "immediate"
      }, {
      name         = "rds.force_ssl"
      value        = 1
      apply_method = "immediate"
    }
  ] : [
    {
      name         = "require_secure_transport"
      value        = "ON"
      apply_method = "immediate"
    }
  ]

  create_db_parameter_group      = true
  db_parameter_group_name        = var.aws_resource_identifier
  db_parameter_group_family      = var.aws_aurora_database_group_family
  db_parameter_group_description = "${var.aws_resource_identifier} example DB parameter group"
  db_parameter_group_parameters = var.aws_aurora_engine == "aurora-postgresql" ? [
    {
      name         = "log_min_duration_statement"
      value        = 4000
      apply_method = "immediate"
    }
  ] : []
  enabled_cloudwatch_logs_exports = var.aws_aurora_engine == "aurora-postgresql" ? ["postgresql"] : ["audit","error","general","slowquery"]
  tags = {
    Name = "${var.aws_resource_identifier} - Aurora"
  }
}

resource "random_password" "rds" {
  length = 10
  special = false
}

// Creates a secret manager secret for the databse credentials
resource "aws_secretsmanager_secret" "database_credentials" {
   name   = "${var.aws_resource_identifier_supershort}-ec2db-pub-${random_string.random_sm.result}"
}
 
resource "aws_secretsmanager_secret_version" "database_credentials_sm_secret_version" {
  secret_id = aws_secretsmanager_secret.database_credentials.id
  secret_string = <<EOF
   {
    "key": "database_password",
    "value": "${sensitive(random_password.rds.result)}"
   }
EOF
}

// Creates a secret manager secret for the databse credentials
resource "aws_secretsmanager_secret" "aurora_database_credentials" {
  name   = "${var.aws_resource_identifier_supershort}-aurora-${random_string.random_sm.result}"
}

# Username and Password are repeated for compatibility with proxy and legacy code.
resource "aws_secretsmanager_secret_version" "database_credentials_sm_secret_version_dev" {
  secret_id = aws_secretsmanager_secret.aurora_database_credentials.id
  secret_string = jsonencode({
   username          = sensitive(module.aurora_cluster.cluster_master_username)
   password          = sensitive(module.aurora_cluster.cluster_master_password)
   DB_ENGINE         = sensitive(local.dba_engine)
   DB_ENGINE_VERSION = sensitive(module.aurora_cluster.cluster_engine_version_actual)
   DB_USER           = sensitive(module.aurora_cluster.cluster_master_username)
   DB_PASSWORD       = sensitive(module.aurora_cluster.cluster_master_password)
   DB_NAME           = sensitive(module.aurora_cluster.cluster_database_name == null ? "" : module.aurora_cluster.cluster_database_name)
   DB_PORT           = sensitive(module.aurora_cluster.cluster_port)
   DB_HOST           = sensitive(module.aurora_cluster.cluster_endpoint)
  })
}

resource "random_string" "random_sm" {
  length    = 5
  lower     = true
  special   = false
  numeric   = false
}

### All of this added to handle snapshots
resource "aws_db_cluster_snapshot" "db_snapshot" {
  count                          = var.aws_aurora_snapshot_name != "" ? ( var.aws_aurora_snapshot_overwrite ? 0 : 1 ) : 0 
  db_cluster_identifier          = var.aws_aurora_cluster_name != "" ? var.aws_aurora_cluster_name : var.aws_resource_identifier
  db_cluster_snapshot_identifier = var.aws_aurora_snapshot_name
  lifecycle {
    ignore_changes = all
  }
}

resource "aws_db_cluster_snapshot" "overwrite_db_snapshot" {
  count                          = var.aws_aurora_snapshot_name != "" ? ( var.aws_aurora_snapshot_overwrite ? 1 : 0 ) : 0
  db_cluster_identifier          = var.aws_aurora_cluster_name != "" ? var.aws_aurora_cluster_name : var.aws_resource_identifier
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
  value = module.aurora_cluster.cluster_id
}

output "aurora_secret_name" {
  value = aws_secretsmanager_secret.aurora_database_credentials.name
}

output "aurora_db_endpoint" {
  value = module.aurora_cluster.cluster_endpoint
}