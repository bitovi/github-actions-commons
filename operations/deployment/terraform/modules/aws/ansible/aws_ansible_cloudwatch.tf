
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

#resource "local_file" "cloudwatch_config" {
#  count = var.aws_ec2_cloudwatch_enable ? 1 : 0
#  filename = format("%s/%s", abspath(path.root), "bitovi-cloudwatch.json")
#  content = <<-EOT
#{
#    "agent": {
#      "metrics_collection_interval": 5,
#      "run_as_user": "root"
#    },
#    "logs": {
#      "logs_collected": {
#            "files": {
#              "collect_list": [
#                    {
#                      "file_path": "/var/lib/docker/containers/*/*.log",
#                      "log_group_name": "${var.aws_ec2_cloudwatch_lg_name}",
#                      "log_stream_name": "{instance_id}",
#                      "timestamp_format": "%b %d %H:%M:%S",
#                      "timezone": "Local"
#                    }
#              ]
#            }
#      }
#    }
#}
#EOT
#}

