locals {
  # Get the correct engine to be used in the proxy if valid. 
  #Aurora MySQL, RDS for MariaDB, and RDS for MySQL databases, specify MYSQL.
  #For Aurora PostgreSQL and RDS for PostgreSQL databases, specify POSTGRESQL.
  #For RDS for Microsoft SQL Server, specify SQLSERVER. 
  engine_mapping = {
    "sqlserver" = "SQLSERVER"
    "postgres"  = "POSTGRES"
    "mysql"     = "MYSQL"
    "mariadb"   = "MYSQL"
  }
  matching_engine = one(compact([for key, value in local.engine_mapping : strcontains(lower(local.db_engine), key) ? value : ""]))
  # Auth types are MYSQL_NATIVE_PASSWORD, POSTGRES_SCRAM_SHA_256, POSTGRES_MD5, and SQL_SERVER_AUTHENTICATION.
  auth_mapping = {
    "sqlserver" = "SQL_SERVER_AUTHENTICATION"
    "postgres"  = "POSTGRES_SCRAM_SHA_256"
    "mysql"     = "MYSQL_NATIVE_PASSWORD"
    "mariadb"   = "MYSQL_NATIVE_PASSWORD"
  }
  auth_selected = one(compact([for key, value in local.auth_mapping : strcontains(lower(local.db_engine), key) ? value : ""]))
  ###
  db_engine         = var.aws_db_proxy_cluster ? data.aws_rds_cluster.db[0].engine : data.aws_db_instance.db[0].engine
  db_port           = var.aws_db_proxy_cluster ? tonumber(data.aws_rds_cluster.db[0].port) : tonumber(data.aws_db_instance.db[0].db_instance_port)
  db_security_group = var.aws_db_proxy_cluster ? data.aws_rds_cluster.db[0].vpc_security_group_ids : data.aws_db_instance.db[0].vpc_security_groups
}

data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

data "aws_secretsmanager_secret_version" "database_credentials" {
  secret_id = var.aws_db_proxy_secret_name
}

data "aws_db_instance" "db" {
  count = var.aws_db_proxy_cluster ? 0 : 1
  db_instance_identifier = var.aws_db_proxy_database_id
}

data "aws_rds_cluster" "db" {
  count = var.aws_db_proxy_cluster ? 1 : 0
  cluster_identifier = var.aws_db_proxy_database_id
}

resource "aws_db_proxy" "rds_proxy" {
  count                 = (strcontains(lower(local.db_engine),"sqlserver") || strcontains(lower(local.db_engine),"postgres") || strcontains(lower(local.db_engine),"mysql") || strcontains(lower(local.db_engine),"mariadb")) ? 1 : 0
  #count                  = true ? 1 : 0
  name                   = var.aws_db_proxy_name
  debug_logging          = true
  engine_family          = local.matching_engine
  idle_client_timeout    = 1800
  require_tls            = var.aws_db_proxy_tls
  role_arn               = aws_iam_role.rds_proxy.arn
  vpc_security_group_ids = [aws_security_group.sg_rds_proxy.id]
  vpc_subnet_ids         = var.aws_selected_subnets

  auth {
    auth_scheme = "SECRETS"
    client_password_auth_type = var.aws_db_proxy_client_password_auth_type != "" ? var.aws_db_proxy_client_password_auth_type : local.auth_selected
    description = "RDS Proxy for master user"
    iam_auth    = "DISABLED"
    secret_arn  = data.aws_secretsmanager_secret_version.database_credentials.arn
  }
  lifecycle {
    ignore_changes = [ debug_logging ]
  }
  depends_on = [ data.aws_rds_cluster.db,data.aws_db_instance.db ]
}

resource "aws_db_proxy_default_target_group" "default" {
  db_proxy_name = aws_db_proxy.rds_proxy[0].name

  connection_pool_config {
    connection_borrow_timeout    = 120
    max_connections_percent      = 100
    max_idle_connections_percent = 50
 }
}

resource "aws_db_proxy_target" "db_instance" {
  count = var.aws_db_proxy_cluster ? 0 : 1
  db_instance_identifier = var.aws_db_proxy_database_id
  db_proxy_name          = aws_db_proxy.rds_proxy[0].name
  target_group_name      = aws_db_proxy_default_target_group.default.name

  depends_on = [ aws_db_proxy.rds_proxy ]
}

resource "aws_db_proxy_target" "db_cluster" {
  count = var.aws_db_proxy_cluster ? 1 : 0
  db_cluster_identifier  = var.aws_db_proxy_database_id
  db_proxy_name          = aws_db_proxy.rds_proxy[0].name
  target_group_name      = aws_db_proxy_default_target_group.default.name

  depends_on = [ aws_db_proxy.rds_proxy ]
}


################
# RDS Proxy SG #
################

## Proxy --> to outside
## Proxy --> From db sg
## Proxy ---> From extras
## Proxy ---> From all internal

# Proxy SG to outside world
resource "aws_security_group" "sg_rds_proxy" {
  name        = var.aws_db_proxy_security_group_name != "" ? var.aws_db_proxy_security_group_name : "SG for ${var.aws_resource_identifier} - RDS Proxy"
  description = "SG for ${var.aws_resource_identifier} - RDS Proxy"
  vpc_id      = var.aws_selected_vpc_id

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }
}

# Proxy SG from DB SG
resource "aws_security_group_rule" "sg_rds_proxy_db_sgs" {
  count                    = var.aws_db_proxy_database_security_group_allow ? length(local.db_security_group) : 0
  type                     = "ingress"
  from_port                = local.db_port
  to_port                  = local.db_port
  protocol                 = "tcp"
  source_security_group_id = local.db_security_group[count.index]
  security_group_id        = aws_security_group.sg_rds_proxy.id
}

# Proxy SG's incoming from extras
resource "aws_security_group_rule" "sg_rds_proxy_extras" {
  count                    = length(local.rds_proxy_allowed_security_groups)
  type                     = "ingress"
  from_port                = local.db_port
  to_port                  = local.db_port
  protocol                 = "tcp"
  source_security_group_id = local.rds_proxy_allowed_security_groups[count.index]
  security_group_id        = aws_security_group.sg_rds_proxy.id
}

# Proxy SG incoming from 0.0.0.0
resource "aws_security_group_rule" "sg_rds_proxy_outside" {
  count                    = var.aws_db_proxy_allow_all_incoming ? 1 : 0
  type                     = "ingress"
  from_port                = local.db_port
  to_port                  = local.db_port
  protocol                 = "tcp"
  source_security_group_id = local.rds_proxy_allowed_security_groups[count.index]
  security_group_id        = aws_security_group.sg_rds_proxy.id
}
locals {
  rds_proxy_allowed_security_groups = var.aws_db_proxy_allowed_security_group != null ? [for n in split(",", var.aws_db_proxy_allowed_security_group) : n] : []
}

##############
# Cloudwatch #
############## 

resource "aws_cloudwatch_log_group" "this" {
  count             = var.aws_db_proxy_cloudwatch_enable ? 1 : 0
  name              = "/aws/rds/proxy/${aws_db_proxy.rds_proxy[0].name}"
  retention_in_days = tonumber(var.aws_db_proxy_cloudwatch_retention_days)
}

##########################
# IAM Role for RDS proxy #
##########################

resource "aws_iam_role" "rds_proxy" {
  name = "${var.aws_resource_identifier}-RdsProxyRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "rds.amazonaws.com"
      }
      }
    ]
  })
}

resource "aws_iam_policy" "rds_proxy_iam" {
  name = "${var.aws_resource_identifier}-RdsProxySecretsManager"
  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "secretsmanager:GetSecretValue",
                "secretsmanager:GetResourcePolicy",
                "secretsmanager:DescribeSecret",
                "secretsmanager:ListSecretVersionIds"
            ],
            "Resource": [
                "${data.aws_secretsmanager_secret_version.database_credentials.arn}"
            ]
        },
        {
            "Effect": "Allow",
            "Action": "kms:Decrypt",
            "Resource": "arn:aws:kms:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:key/aws/secretsmanager",
            "Condition": {
                "StringEquals": {
                    "kms:ViaService": "secretsmanager.${data.aws_region.current.name}.amazonaws.com"
                }
            }
        }
    ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "rds_policy" {
  role       = aws_iam_role.rds_proxy.name
  policy_arn = aws_iam_policy.rds_proxy_iam.arn
}

output "aws_db_proxy_endpoint" {
  value = aws_db_proxy.rds_proxy[0].endpoint
}