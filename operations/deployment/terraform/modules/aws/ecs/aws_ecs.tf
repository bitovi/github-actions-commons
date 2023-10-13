resource "aws_ecs_cluster" "cluster" {
  name = "${local.aws_ecs_cluster_name}-cluster"

  setting {
    name  = "containerInsights"
    value = var.aws_ecs_cloudwatch_enable ? "enabled" : "disabled"
  }
  tags = {
    Name = "${var.aws_resource_identifier}-ecs-cluster"
  }
}

locals {
  aws_ecs_app_image           = [for n in split(",", var.aws_ecs_app_image) : n]
  aws_ecs_cluster_name        = var.aws_ecs_cluster_name  != "" ? var.aws_ecs_cluster_name : "${var.aws_resource_identifier}"
  aws_ecs_task_name           = var.aws_ecs_task_name     != "" ? [for n in split(",", var.aws_ecs_task_name) : n]               : [for _ in range(local.tasks_count) : "${var.aws_resource_identifier}-app" ]
  aws_ecs_node_count          = var.aws_ecs_node_count    != "" ? [for n in split(",", var.aws_ecs_node_count)    : tonumber(n)] : [for _ in range(local.tasks_count) : 1]
  aws_ecs_task_cpu            = var.aws_ecs_task_cpu      != "" ? [for n in split(",", var.aws_ecs_task_cpu)      : tonumber(n)] : [for _ in range(local.tasks_count) : 256] 
  aws_ecs_task_mem            = var.aws_ecs_task_mem      != "" ? [for n in split(",", var.aws_ecs_task_mem)      : tonumber(n)] : [for _ in range(local.tasks_count) : 512]
  aws_ecs_container_cpu       = var.aws_ecs_container_cpu != "" ? [for n in split(",", var.aws_ecs_container_cpu) : tonumber(n)] : [for _ in range(length(local.aws_ecs_app_image)) : null] 
  aws_ecs_container_mem       = var.aws_ecs_container_mem != "" ? [for n in split(",", var.aws_ecs_container_mem) : tonumber(n)] : [for _ in range(length(local.aws_ecs_app_image)) : null]
  aws_ecs_task_json_definition_file = var.aws_ecs_task_json_definition_file != "" ? [for n in split(",", var.aws_ecs_task_json_definition_file) : n] : []
}

resource "aws_ecs_task_definition" "ecs_task" {
  count                    = length(local.aws_ecs_app_image)
  family                   = var.aws_ecs_task_name  != "" ? local.aws_ecs_task_name[count.index] : "${local.aws_ecs_task_name[count.index]}${count.index}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = local.aws_ecs_task_cpu[count.index]
  memory                   = local.aws_ecs_task_mem[count.index]
  execution_role_arn       = data.aws_iam_role.ecsTaskExecutionRole.arn
  container_definitions = sensitive(jsonencode([
    {
      "image": local.aws_ecs_app_image[count.index],
      "cpu": local.aws_ecs_container_cpu[count.index],
      "memory": local.aws_ecs_container_mem[count.index],
      "name": var.aws_ecs_task_name != "" ? local.aws_ecs_task_name[count.index] : "${local.aws_ecs_task_name[count.index]}${count.index}",
      "networkMode": "awsvpc",
      "portMappings": [
        {
          "name": "port-${local.aws_ecs_container_port[count.index]}",
          "containerPort": tonumber(local.aws_ecs_container_port[count.index]),
          "hostPort": tonumber(local.aws_ecs_container_port[count.index]),
          "protocol": "tcp",
          "appProtocol": "http"
        }
      ],
      "environment": local.env_repo_vars
      "logConfiguration": var.aws_ecs_cloudwatch_enable ? {
        "logDriver": "awslogs",
        "options": {
          "awslogs-create-group": "true",
          "awslogs-region": var.aws_region_current_name,
          "awslogs-group": var.aws_ecs_cloudwatch_lg_name,
          "awslogs-stream-prefix": aws_ecs_cluster.cluster.name
        }
      } : null
    }
  ]))
}

resource "aws_ecs_task_definition" "ecs_task_from_json" {
  count                    = length(local.aws_ecs_task_json_definition_file)
  family                   = var.aws_ecs_task_name != "" ? local.aws_ecs_task_name[count.index] : "${local.aws_ecs_task_name[count.index]}${count.index}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = local.aws_ecs_task_cpu[count.index]
  memory                   = local.aws_ecs_task_mem[count.index]
  execution_role_arn       = data.aws_iam_role.ecsTaskExecutionRole.arn
  container_definitions    = sensitive(file("../../ansible/clone_repo/app/${var.app_repo_name}/${local.aws_ecs_task_json_definition_file[count.index]}"))
}

locals {
  tasks_arns  = concat(aws_ecs_task_definition.ecs_task[*].arn,aws_ecs_task_definition.ecs_task_from_json[*].arn)
  tasks_count = length(local.aws_ecs_app_image) + length(local.aws_ecs_task_json_definition_file)
}

resource "aws_ecs_service" "ecs_service" {
  count            = local.tasks_count
  name             = var.aws_ecs_service_name != "" ? "${var.aws_ecs_service_name}${count.index}" : "${var.aws_resource_identifier}-${count.index}-service"
  cluster          = aws_ecs_cluster.cluster.id
  task_definition = local.tasks_arns[count.index]

  desired_count    = local.aws_ecs_node_count[count.index]
  launch_type      = "FARGATE"

  network_configuration {
    security_groups  = [aws_security_group.ecs_sg.id]
    subnets          = var.aws_selected_subnets
    assign_public_ip = var.aws_ecs_assign_public_ip
  }

  load_balancer {
    target_group_arn = aws_alb_target_group.lb_targets[count.index].id
    container_name   = var.aws_ecs_task_name != "" ? local.aws_ecs_task_name[count.index] : "${local.aws_ecs_task_name[count.index]}${count.index}"
    container_port   = local.aws_ecs_container_port[count.index]
  }
  depends_on = [aws_alb_listener.lb_listener, aws_ecs_task_definition.ecs_task, aws_ecs_task_definition.ecs_task_from_json]
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