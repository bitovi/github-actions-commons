resource "aws_ecs_cluster" "cluster" {
  name = var.aws_ecs_cluster_name != "" ? var.aws_ecs_cluster_name : "${var.aws_resource_identifier}-cluster"

  setting {
    name  = "containerInsights"
    value = var.aws_ecs_cloudwatch_enable ? "enabled" : "disabled"
  }
  #configuration {
  #  execute_command_configuration {
  #    log_configuration {
  #      cloud_watch_log_group_name = var.aws_ecs_cloudwatch_lg_name
  #      s3_bucket_name             = var.aws_ecs_logs_s3_bucket
  #      s3_key_prefix              = var.aws_ecs_logs_s3_bucket_prefix
  #    }
  #  }
  #}

  tags = {
    Name = "${var.aws_resource_identifier}-ecs-cluster"
  }
}

resource "aws_ecs_task_definition" "ecs_task" {
  count                    = var.aws_ecs_cloudwatch_enable ? 0 : 1
  family                   = local.aws_ecs_task_name
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = tonumber(var.aws_ecs_app_cpu)
  memory                   = tonumber(var.aws_ecs_app_mem)
  execution_role_arn       = data.aws_iam_role.ecsTaskExecutionRole.arn
  container_definitions = <<DEFINITION
[
  {
    "runtimePlatform": {
        "cpuArchitecture": "X86_64",
        "operatingSystemFamily": "LINUX"
    },
    "image": "${var.aws_ecs_app_image}",
    "cpu": ${var.aws_ecs_app_cpu},
    "memory": ${var.aws_ecs_app_mem},
    "name": "${local.aws_ecs_task_name}",
    "networkMode": "awsvpc",
    "portMappings": [
      {
        "name": "port-${var.aws_ecs_container_port}",
        "containerPort": ${tonumber(var.aws_ecs_container_port)},
        "hostPort": ${tonumber(var.aws_ecs_container_port)},
        "protocol": "tcp",
        "appProtocol": "http"
      }
    ]
  }
]
DEFINITION
}

resource "aws_ecs_task_definition" "ecs_task_cw" {
  count                    = var.aws_ecs_cloudwatch_enable ? 1 : 0
  family                   = local.aws_ecs_task_name
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = tonumber(var.aws_ecs_app_cpu)
  memory                   = tonumber(var.aws_ecs_app_mem)
  execution_role_arn       = data.aws_iam_role.ecsTaskExecutionRole.arn
  container_definitions = <<DEFINITION
[
  {
    "image": "${var.aws_ecs_app_image}",
    "cpu": ${var.aws_ecs_app_cpu},
    "memory": ${var.aws_ecs_app_mem},
    "name": "${local.aws_ecs_task_name}",
    "networkMode": "awsvpc",
    "portMappings": [
      {
        "name": "port-${var.aws_ecs_container_port}",
        "containerPort": ${tonumber(var.aws_ecs_container_port)},
        "hostPort": ${tonumber(var.aws_ecs_container_port)},
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
  name             = var.aws_ecs_service_name != "" ? var.aws_ecs_service_name : "${var.aws_resource_identifier}-service"
  cluster          = aws_ecs_cluster.cluster.id
  task_definition  = var.aws_ecs_cloudwatch_enable? aws_ecs_task_definition.ecs_task_cw[0].arn : aws_ecs_task_definition.ecs_task[0].arn
  desired_count    = tonumber(var.aws_ecs_node_count)
  launch_type      = "FARGATE"

  network_configuration {
    security_groups  = [aws_security_group.ecs_sg.id]
    subnets          = var.aws_selected_subnets
    assign_public_ip = var.aws_ecs_assign_public_ip
  }

  load_balancer {
   # target_group_arn = aws_alb_target_group.lb_targets[0].id
    target_group_arn = aws_alb_target_group.lb_targets.id
    container_name   = local.aws_ecs_task_name
    container_port   = tonumber(var.aws_ecs_container_port)
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
  name = "ecsTaskExecutionRole"
}

locals {
  aws_ecs_task_name      = var.aws_ecs_task_name != "" ? var.aws_ecs_task_name : "${var.aws_resource_identifier}-app"
}