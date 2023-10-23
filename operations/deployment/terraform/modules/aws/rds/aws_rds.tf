resource "aws_security_group" "rds_db_security_group" {
  name        = var.aws_rds_db_security_group_name != null ? var.aws_rds_db_security_group_name : "SG for ${var.aws_resource_identifier} - RDS"
  description = "SG for ${var.aws_resource_identifier} - RDS"
  vpc_id      = var.aws_selected_vpc_id
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
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
  aws_rds_db_subnets = var.aws_rds_db_subnets  != null ? [for n in split(",", var.aws_rds_db_subnets)  : (n)] :  var.aws_subnets_vpc_subnets_ids
}

resource "aws_db_subnet_group" "selected" {
  name       = "${var.aws_resource_identifier}-rds"
  subnet_ids = local.aws_rds_db_subnets
  tags = {
    Name = "${var.aws_resource_identifier}-rds"
  }
}

resource "aws_db_instance" "default" {
  identifier                       = var.aws_rds_db_name != null ? var.aws_rds_db_name : var.aws_resource_identifier
  engine                           = var.aws_rds_db_engine
  engine_version                   = var.aws_rds_db_engine_version
  db_subnet_group_name             = aws_db_subnet_group.selected.name
  db_name                          = var.aws_rds_db_name != null ? var.aws_rds_db_name : null
  port                             = var.aws_rds_db_port != null ? tonumber(var.aws_rds_db_port) : null
  allocated_storage                = tonumber(var.aws_rds_db_allocated_storage)
  max_allocated_storage            = tonumber(var.aws_rds_db_max_allocated_storage)
  instance_class                   = var.aws_rds_db_instance_class
  username                         = var.aws_rds_db_user != null ? var.aws_rds_db_user : "dbuser"
  password                         = random_password.rds.result
  skip_final_snapshot              = var.aws_rds_db_final_snapshot == "" ? true : false
  final_snapshot_identifier        = var.aws_rds_db_final_snapshot
  snapshot_identifier              = var.aws_rds_db_restore_snapshot_identifier 
  publicly_accessible              = var.aws_rds_db_publicly_accessible 
  enabled_cloudwatch_logs_exports  = [var.aws_rds_db_cloudwatch_logs_exports]
  vpc_security_group_ids           = [aws_security_group.rds_db_security_group.id]
  tags = {
    Name = "${var.aws_resource_identifier}-rds"
  }
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

// Creates a secret manager secret for the databse credentials
resource "aws_secretsmanager_secret" "rds_database_credentials" {
  name   = "${var.aws_resource_identifier_supershort}-rdsdb-pub-${random_string.random_sm.result}"
}

resource "aws_secretsmanager_secret_version" "database_credentials_sm_secret_version_dev" {
  secret_id = aws_secretsmanager_secret.rds_database_credentials.id
  secret_string = jsonencode({
   DB_ENGINE         = sensitive(aws_db_instance.default.engine)
   DB_ENGINE_VERSION = sensitive(aws_db_instance.default.engine_version)
   DB_USER           = sensitive(aws_db_instance.default.username)
   DB_PASSWORD       = sensitive(aws_db_instance.default.password)
   DB_NAME           = sensitive(aws_db_instance.default.db_name)
   DB_PORT           = sensitive(aws_db_instance.default.port)
   DB_HOST           = sensitive(aws_db_instance.default.address)
  })
}

resource "random_password" "rds" {
  length = 25
  special = false
  lifecycle {
  ignore_changes = all
  }
}

resource "random_string" "random_sm" {
  length    = 5
  lower     = true
  special   = false
  numeric   = false
}

data "aws_vpc" "selected" {
  count = var.aws_selected_vpc_id != null ? 1 : 0
  id    = var.aws_selected_vpc_id
}