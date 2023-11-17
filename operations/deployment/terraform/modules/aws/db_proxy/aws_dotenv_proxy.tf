# Additional postgres configuration in postgres.tf

locals {
  var_name  = var.aws_rds_db_proxy ? "DB_PROXY" : var.aws_aurora_proxy ? "DBA_PROXY" : "PROXY_ENDPOINT"
  file_name = var.aws_rds_db_proxy ? "rds" : var.aws_aurora_proxy ? "aurora" : "proxy"
  dot_env   = <<-EOT
#### Proxy values for ${local.file_name}
${local.var_name}="${aws_db_proxy.rds_proxy[0].endpoint}"
EOT
}

output "proxy_dot_env" {
  value = local.dot_env
}