# Additional postgres configuration in postgres.tf

resource "local_file" "redis-dotenv" {
  filename = format("%s/%s", abspath(path.root), "redis.env")
  content  = <<-EOT

#### REDIS values
RD_ENGINE="${aws_db_instance.default.engine}"
RD_ENGINE_VERSION="${aws_db_instance.default.engine_version}"
RD_USER="${aws_db_instance.default.username}"
RD_PASSWORD="${aws_db_instance.default.password}"
RD_NAME="${aws_db_instance.default.db_name}"
RD_PORT="${aws_db_instance.default.port}"
RD_HOST="${aws_db_instance.default.address}"
EOT
}