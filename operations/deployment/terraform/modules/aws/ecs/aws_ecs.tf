resource "aws_ecs_cluster" "cluster" {
  name = var.aws_ecs_cluster_name != "" ? var.aws_ecs_cluster_name : "${var.aws_resource_identifier}-cluster"

  setting {
    name  = "containerInsights"
    value = var.aws_ecs_cloudwatch_enable ? "enabled" : "disabled"
  }
#  configuration {
#    execute_command_configuration {
#      log_configuration {
#        s3_bucket_name             = var.aws_ecs_logs_s3_bucket
#        s3_key_prefix              = var.aws_ecs_logs_s3_bucket_prefix
#      }
#    }
#  }

  tags = {
    Name = "${var.aws_resource_identifier}-ecs-cluster"
  }
}

locals {
  aws_aws_ecs_app_image       = [for n in split(",", var.aws_ecs_app_image) : n]
  aws_ecs_task_name           = var.aws_ecs_task_name != ""           ? var.aws_ecs_task_name : "${var.aws_resource_identifier}-app"
  aws_ecs_node_count          = var.aws_ecs_node_count != ""          ? [for n in split(",", var.aws_ecs_node_count) : tonumber(n)] : [for _ in range(length(local.aws_aws_ecs_app_image)) : 1]
  aws_ecs_app_cpu             = var.aws_ecs_app_cpu != ""             ? [for n in split(",", var.aws_ecs_app_cpu)    : tonumber(n)] : [for _ in range(length(local.aws_aws_ecs_app_image)) : 256] 
  aws_ecs_app_mem             = var.aws_ecs_app_mem != ""             ? [for n in split(",", var.aws_ecs_app_mem)    : tonumber(n)] : [for _ in range(length(local.aws_aws_ecs_app_image)) : 512]
  aws_ecs_env_vars            = var.aws_ecs_env_vars != ""            ? [for n in split("|", var.aws_ecs_env_vars)   : n ]          : [for _ in range(length(local.aws_aws_ecs_app_image)) : "{}"]
}

resource "aws_ecs_task_definition" "ecs_task" {
  count                    = var.aws_ecs_cloudwatch_enable ? 0 : length(local.aws_aws_ecs_app_image)
  family                   = "${local.aws_ecs_task_name}${count.index}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = local.aws_ecs_app_cpu[count.index]
  memory                   = local.aws_ecs_app_mem[count.index]
  execution_role_arn       = data.aws_iam_role.ecsTaskExecutionRole.arn
  container_definitions = <<DEFINITION
[
  {
    "runtimePlatform": {
        "cpuArchitecture": "X86_64",
        "operatingSystemFamily": "LINUX"
    },
    "image": "${local.aws_aws_ecs_app_image[count.index]}",
    "cpu": ${local.aws_ecs_app_cpu[count.index]},
    "memory": ${local.aws_ecs_app_mem[count.index]},
    "name": "${local.aws_ecs_task_name}${count.index}",
    "networkMode": "awsvpc",
    "environment": [${local.aws_ecs_env_vars[count.index]}],
    "portMappings": [
      {
        "name": "port-${local.aws_ecs_container_port[count.index]}",
        "containerPort": ${tonumber(local.aws_ecs_container_port[count.index])},
        "hostPort": ${tonumber(local.aws_ecs_container_port[count.index])},
        "protocol": "tcp",
        "appProtocol": "http"
      }
    ]
  }
]
DEFINITION
}

#    "environment": [${local.aws_ecs_env_vars[count.index]}]


resource "aws_ecs_task_definition" "ecs_task_cw" {
  count                    = var.aws_ecs_cloudwatch_enable ? length(local.aws_aws_ecs_app_image) : 0
  family                   = "${local.aws_ecs_task_name}${count.index}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = local.aws_ecs_app_cpu[count.index]
  memory                   = local.aws_ecs_app_mem[count.index]
  execution_role_arn       = data.aws_iam_role.ecsTaskExecutionRole.arn
  container_definitions = <<DEFINITION
[
  {
    "runtimePlatform": {
        "cpuArchitecture": "X86_64",
        "operatingSystemFamily": "LINUX"
    },
    "image": "${local.aws_aws_ecs_app_image[count.index]}",
    "cpu": ${local.aws_ecs_app_cpu[count.index]},
    "memory": ${local.aws_ecs_app_mem[count.index]},
    "name": "${local.aws_ecs_task_name}${count.index}",
    "networkMode": "awsvpc",
    "environment": [${local.aws_ecs_env_vars[count.index]}],
    "portMappings": [
      {
        "name": "port-${local.aws_ecs_container_port[count.index]}",
        "containerPort": ${tonumber(local.aws_ecs_container_port[count.index])},
        "hostPort": ${tonumber(local.aws_ecs_container_port[count.index])},
        "protocol": "tcp",
        "appProtocol": "http"
      }
    ],
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-region":"${var.aws_region_current_name}",
        "awslogs-group":"${var.aws_ecs_cloudwatch_lg_name}",
        "tag":"{{.Name}}"
      }
    }
  }
]
DEFINITION
}

resource "aws_ecs_service" "ecs_service_with_lb" {
  count            = length(local.aws_aws_ecs_app_image)
  name             = var.aws_ecs_service_name != "" ? "${var.aws_ecs_service_name}${count.index}" : "${var.aws_resource_identifier}-${count.index}-service"
  cluster          = aws_ecs_cluster.cluster.id
  task_definition  = var.aws_ecs_cloudwatch_enable ? aws_ecs_task_definition.ecs_task_cw[count.index].arn : aws_ecs_task_definition.ecs_task[count.index].arn
  desired_count    = local.aws_ecs_node_count[count.index]
  launch_type      = "FARGATE"

  network_configuration {
    security_groups  = [aws_security_group.ecs_sg.id]
    subnets          = var.aws_selected_subnets
    assign_public_ip = var.aws_ecs_assign_public_ip
  }

  load_balancer {
   # target_group_arn = aws_alb_target_group.lb_targets[0].id
    target_group_arn = aws_alb_target_group.lb_targets[count.index].id
    container_name   = "${local.aws_ecs_task_name}${count.index}"
    container_port   = local.aws_ecs_container_port[count.index]
  }
  depends_on = [aws_alb_listener.lb_listener]
}

# Cloudwatch config

resource "aws_cloudwatch_log_group" "ecs_cw_log_group" {
  count             = var.aws_ecs_cloudwatch_enable ? 1 : 0
  name              = var.aws_ecs_cloudwatch_lg_name
  skip_destroy      = var.aws_ecs_cloudwatch_skip_destroy
  retention_in_days = tonumber(var.aws_ecs_cloudwatch_retention_days)
}

# IAM

data "aws_iam_role" "ecsTaskExecutionRole" {
  name = var.aws_ecs_task_execution_role
}