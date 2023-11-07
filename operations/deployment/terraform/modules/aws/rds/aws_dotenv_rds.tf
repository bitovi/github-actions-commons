# Additional postgres configuration in postgres.tf

resource "local_file" "rds-dotenv" {
  filename = format("%s/%s", abspath(path.root), "rds.env")
  content  = <<-EOT

#### RDS values
DB_ENGINE="${aws_db_instance.default.engine}"
DB_ENGINE_VERSION="${aws_db_instance.default.engine_version}"
DB_USER="${aws_db_instance.default.username}"
DB_PASSWORD="${aws_db_instance.default.password}"
DB_NAME="${aws_db_instance.default.db_name}"
DB_PORT="${aws_db_instance.default.port}"
DB_HOST="${aws_db_instance.default.address}"
EOT
}