# Additional postgres configuration in postgres.tf

locals {
  var_name  = var.aws_rds_db_proxy ? "DB_PROXY" : var.aws_aurora_proxy ? "DBA_PROXY" : "PROXY_ENDPOINT"
  file_name = var.aws_rds_db_proxy ? "rds" : var.aws_aurora_proxy ? "aurora" : "proxy"
}


resource "local_file" "aurora-dotenv" {
  filename = format("%s/%s", abspath(path.root), "proxy.${local.file_name}.env")
  content  = <<-EOT

#### Proxy values
${local.var_name}=${aws_db_proxy.rds_proxy[0].endpoint}
EOT
}