
resource "aws_cloudwatch_log_group" "cw_log_group" {
  count             = var.docker_cloudwatch_enable ? 1 : 0
  name              = var.docker_cloudwatch_lg_name
  skip_destroy      = var.docker_cloudwatch_skip_destroy
  retention_in_days = tonumber(var.docker_cloudwatch_retention_days)
}

resource "local_file" "cloudwatch_docker_config" {
  count = var.docker_cloudwatch_enable ? 1 : 0
  filename = format("%s/%s", abspath(path.root), "bitovi-daemon.json")
  content = <<-EOT
{
  "log-driver": "awslogs",
  "log-opts": {
    "awslogs-region": "${var.aws_region_current_name}",
    "awslogs-group": "${var.docker_cloudwatch_lg_name}",
    "tag": "{{.Name}}"
  }
}
EOT
}