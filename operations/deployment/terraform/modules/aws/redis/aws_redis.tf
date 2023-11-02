
# Security groups
resource "aws_security_group" "redis_security_group" {
  name        = var.aws_redis_security_group_name != null ? var.aws_redis_security_group_name : "SG for ${var.aws_resource_identifier} - Redis"
  description = "SG for ${var.aws_resource_identifier} - Redis"
  vpc_id      = var.aws_selected_vpc_id
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }
  tags = {
    Name = "${var.aws_resource_identifier}-redis"
  }
}

resource "aws_security_group_rule" "ingress_redis" {
  count             = var.aws_redis_ingress_allow_all ? 1 : 0
  type              = "ingress"
  description       = "${var.aws_resource_identifier} - redis Port"
  from_port         = tonumber(aws_elasticache_replication_group.redis_cluster.port)
  to_port           = tonumber(aws_elasticache_replication_group.redis_cluster.port)
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.redis_security_group.id
}

resource "aws_security_group_rule" "ingress_redis_extras" {
  count                    = length(local.aws_redis_allowed_security_groups)
  type                     = "ingress"
  description              = "${var.aws_resource_identifier} - redis ingress extra SG"
  from_port                = tonumber(aws_elasticache_replication_group.redis_cluster.port)
  to_port                  = tonumber(aws_elasticache_replication_group.redis_cluster.port)
  protocol                 = "tcp"
  source_security_group_id = local.aws_redis_allowed_security_groups[count.index]
  security_group_id        = aws_security_group.redis_security_group.id
}

locals {
  aws_redis_allowed_security_groups = var.aws_redis_allowed_security_groups != null ? [for n in split(",", var.aws_redis_allowed_security_groups) : n] : []
  aws_redis_subnets = var.aws_redis_subnets  != null ? [for n in split(",", var.aws_redis_subnets)  : (n)] :  var.aws_selected_subnets
}

resource "aws_elasticache_subnet_group" "selected" {
  name       = "${var.aws_resource_identifier}-redis"
  subnet_ids = local.aws_redis_subnets
  tags = {
    Name = "${var.aws_resource_identifier}-redis"
  }
}

#########
# Redis #
#########

resource "aws_elasticache_replication_group" "redis_cluster" {
  automatic_failover_enabled  = tonumber(var.aws_redis_cache_nodes) > 1 ? true : false
  replication_group_id        = var.aws_redis_replication_group_id != "" ? var.aws_redis_replication_group_id : "${var.aws_resource_identifier}-redis"
  description                 = "Redis cluster for ${var.aws_resource_identifier}" 
  node_type                   = var.aws_redis_node_type
  num_cache_clusters          = tonumber(var.aws_redis_cache_nodes)
  parameter_group_name        = var.aws_redis_parameter_group_name
  port                        = tonumber(var.aws_redis_port)
  
  snapshot_name               = var.aws_redis_snapshot_restore_name
  final_snapshot_identifier   = var.aws_redis_final_snapshot
  user_group_ids              = [aws_elasticache_user_group.redis.user_group_id]
  at_rest_encryption_enabled  = var.aws_redis_at_rest_encryption 
  transit_encryption_enabled  = var.aws_redis_in_transit_encryption
  subnet_group_name           = aws_elasticache_subnet_group.selected.name
  security_group_ids          = [aws_security_group.redis_security_group.id]
  num_node_groups             = tonumber(var.aws_redis_num_node_groups)
  replicas_per_node_group     = tonumber(var.aws_redis_replicas_per_node_group)
  multi_az_enabled            = var.aws_redis_multi_az_enabled


  dynamic "log_delivery_configuration" {
    for_each = var.aws_redis_cloudwatch_enabled ? [var.aws_redis_cloudwatch_enabled] : []

    content {
      destination      = var.aws_redis_cloudwatch_lg_name != "" ? var.aws_redis_cloudwatch_lg_name : "redis/${var.aws_resource_identifier}"
      destination_type = "cloudwatch-logs"
      log_format       = var.aws_redis_cloudwatch_log_format
      log_type         = var.aws_redis_cloudwatch_log_type
    }
  }
}

resource "aws_elasticache_user" "redis" {
  user_id       = var.aws_redis_user
  user_name     = var.aws_redis_user
  access_string = var.aws_redis_user_access_string
  engine        = "REDIS"
  passwords     = [random_password.redis.result]
}

data "aws_elasticache_user" "default" {
  user_id = "default"
}

resource "aws_elasticache_user_group" "redis" {
  engine        = "REDIS"
  user_group_id = var.aws_redis_user_group_name != "" ? var.aws_redis_user_group_name : "${var.aws_resource_identifier}-redis"
  user_ids      = [aws_elasticache_user.redis.user_id,data.aws_elasticache_user.default.user_id]
}

resource "random_password" "redis" {
  length = 24
  special = false
}

locals {
  redis_url = ( aws_elasticache_replication_group.redis_cluster.cluster_enabled ? 
    aws_elasticache_replication_group.redis_cluster.configuration_endpoint_address :
    aws_elasticache_replication_group.redis_cluster.primary_endpoint_address )
  redis_protocol = var.aws_redis_in_transit_encryption ? "rediss" : "redis"
}

output "redis_url" {
  value =  local.redis_url
}

// Creates a secret manager secret for the databse credentials
resource "aws_secretsmanager_secret" "redis_credentials_sl" {
   name   = "${var.aws_resource_identifier_supershort}-redis-single-line${random_string.random.result}"
}

resource "aws_secretsmanager_secret_version" "rediscredentials_sm_secret_version_sl" {
  secret_id = aws_secretsmanager_secret.redis_credentials_sl.id
  secret_string = sensitive("${local.redis_protocol}://${aws_elasticache_user.redis.user_name}:${random_password.redis.result}@${local.redis_url}:${aws_elasticache_replication_group.redis_cluster.port}")
}

// Creates a secret manager secret for the databse credentials
resource "aws_secretsmanager_secret" "redis_credentials" {
   name   = "${var.aws_resource_identifier_supershort}-redis-single-line${random_string.random.result}"
}

resource "aws_secretsmanager_secret_version" "rediscredentials_sm_secret_version" {
  secret_id = aws_secretsmanager_secret.redis_credentials.id
  secret_string = jsonencode({
   username          = sensitive(aws_elasticache_user.redis.user_name)
   password          = sensitive(random_password.redis.result)
   host              = sensitive(local.redis_url)
   port              = sensitive(aws_elasticache_replication_group.redis_cluster.port)
   DB_USER           = sensitive(aws_elasticache_user.redis.user_name)
   DB_USERNAME       = sensitive(aws_elasticache_user.redis.user_name)
   DB_PASSWORD       = sensitive(random_password.redis.result)
   DB_HOST           = sensitive(local.redis_url)
   DB_PORT           = sensitive(aws_elasticache_replication_group.redis_cluster.port)
  })
}

resource "random_string" "random" {
  length    = 5
  lower     = true
  special   = false
  numeric   = false
  lifecycle {
    ignore_changes = all
  }
}

output "redis_secret_name" {
    value = aws_secretsmanager_secret.redis_credentials.name
}

output "redis_connection_string_secret" {
    value = aws_secretsmanager_secret.redis_credentials_sl.name
}

output "redis_endpoint" {
    value =  "${local.redis_protocol}://${local.redis_url}:${aws_elasticache_replication_group.redis_cluster.port}"
}