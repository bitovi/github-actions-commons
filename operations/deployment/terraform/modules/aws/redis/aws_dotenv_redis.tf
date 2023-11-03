# Additional postgres configuration in postgres.tf

resource "local_file" "redis-dotenv" {
  filename = format("%s/%s", abspath(path.root), "redis.env")
  content  = <<-EOT

#### REDIS values
RD_PROTOCOL="${local.redis_protocol}"
RD_USER="${aws_elasticache_user.redis.user_name}"
RD_USERNAME="${aws_elasticache_user.redis.user_name}"
RD_PASSWORD="${random_password.redis.result}"
RD_HOST="${local.redis_url}"
RD_PORT="${aws_elasticache_replication_group.redis_cluster.port}"
RD_CONN_STR="${local.redis_protocol}://${aws_elasticache_user.redis.user_name}:${random_password.redis.result}@${local.redis_url}:${aws_elasticache_replication_group.redis_cluster.port}"
EOT
}