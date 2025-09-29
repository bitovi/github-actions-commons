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
  aws_ecs_app_image           = var.aws_ecs_app_image         != "" ? [for n in split(",", var.aws_ecs_app_image) : n] : []
  aws_ecs_cluster_name        = var.aws_ecs_cluster_name      != "" ? var.aws_ecs_cluster_name : "${var.aws_resource_identifier}"
  aws_ecs_task_name           = var.aws_ecs_task_name         != "" ? [for n in split(",", var.aws_ecs_task_name) : n]                : [for _ in range(local.tasks_count) : "${var.aws_resource_identifier}-app" ]
  aws_ecs_node_count          = var.aws_ecs_node_count        != "" ? [for n in split(",", var.aws_ecs_node_count)    : tonumber(n)]  : [for _ in range(local.tasks_count) : 1]
  aws_ecs_task_network_mode   = var.aws_ecs_task_network_mode != "" ? [for n in split(",", var.aws_ecs_task_network_mode) : n]        : [for _ in range(local.tasks_count) : "awsvpc" ]
  aws_ecs_task_cpu            = var.aws_ecs_task_cpu          != "" ? [for n in split(",", var.aws_ecs_task_cpu)       : tonumber(n)] : [for _ in range(local.tasks_count) : 256] 
  aws_ecs_task_mem            = var.aws_ecs_task_mem          != "" ? [for n in split(",", var.aws_ecs_task_mem)       : tonumber(n)] : [for _ in range(local.tasks_count) : 512]
  aws_ecs_container_cpu       = var.aws_ecs_container_cpu     != "" ? [for n in split(",", var.aws_ecs_container_cpu)  : tonumber(n)] : [for _ in range(length(local.aws_ecs_app_image)) : null] 
  aws_ecs_container_mem       = var.aws_ecs_container_mem     != "" ? [for n in split(",", var.aws_ecs_container_mem)  : tonumber(n)] : [for _ in range(length(local.aws_ecs_app_image)) : null]
  aws_ecs_task_type           = var.aws_ecs_task_type         != "" ? [for n in split(",", var.aws_ecs_task_type) : n] : [for _ in range(local.tasks_count) : (var.aws_ecs_service_launch_type == "FARGATE" || var.aws_ecs_service_launch_type == "EC2" ? var.aws_ecs_service_launch_type : "FARGATE" )]

  aws_ecs_task_json_definition_file = var.aws_ecs_task_json_definition_file != "" ? [for n in split(",", var.aws_ecs_task_json_definition_file) : n] : []
  
  ecsTaskExecutionRole = var.aws_ecs_task_execution_role != "" ? data.aws_iam_role.ecsTaskExecutionRole[0].arn : aws_iam_role.ecsTaskExecutionRole[0].arn
  
  # Calculate tasks_count early to avoid circular dependency
  tasks_count = var.aws_ecs_task_ignore_definition ? 1 : length(local.aws_ecs_app_image) + length(local.aws_ecs_task_json_definition_file)
  tasks_arns  = concat(aws_ecs_task_definition.ecs_task[*].arn,aws_ecs_task_definition.ecs_task_from_json[*].arn,aws_ecs_task_definition.aws_ecs_task_ignore_definition[*].arn)
}

resource "aws_ecs_task_definition" "ecs_task" {
  count                    = var.aws_ecs_task_ignore_definition ? 0 : length(local.aws_ecs_app_image)
  family                   = var.aws_ecs_task_name  != "" ? local.aws_ecs_task_name[count.index] : "${local.aws_ecs_task_name[count.index]}${count.index}"
  network_mode             = local.aws_ecs_task_network_mode[count.index]
  requires_compatibilities = [local.aws_ecs_task_type[count.index]]
  cpu                      = local.aws_ecs_task_cpu[count.index]
  memory                   = local.aws_ecs_task_mem[count.index]
  execution_role_arn       = local.ecsTaskExecutionRole
  container_definitions = sensitive(jsonencode(
    concat(
      [
        {
          "name": var.aws_ecs_task_name != "" ? local.aws_ecs_task_name[count.index] : "${local.aws_ecs_task_name[count.index]}${count.index}",
          "image": local.aws_ecs_app_image[count.index],
          "cpu": local.aws_ecs_container_cpu[count.index],
          "memory": local.aws_ecs_container_mem[count.index],
          "essential": true,
          "networkMode": "awsvpc",
          "portMappings": length(local.aws_ecs_container_port) > 0 ? [
            {
              "name": "port-${local.aws_ecs_container_port[count.index]}",
              "containerPort": local.aws_ecs_container_port[count.index],
              "hostPort": local.aws_ecs_container_port[count.index],
              "protocol": "tcp",
              "appProtocol": "http"
            }
          ] : []
          "environment": local.env_repo_vars,
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
      ]
    )
  ))
}

resource "aws_ecs_task_definition" "ecs_task_from_json" {
  count                    = var.aws_ecs_task_ignore_definition ? 0 : length(local.aws_ecs_task_json_definition_file)
  family                   = var.aws_ecs_task_name != "" ? local.aws_ecs_task_name[count.index + length(local.aws_ecs_app_image)] : "${local.aws_ecs_task_name[count.index + length(local.aws_ecs_app_image)]}${count.index+length(local.aws_ecs_app_image)}"
  network_mode             = local.aws_ecs_task_network_mode[count.index + length(local.aws_ecs_app_image)]
  requires_compatibilities = [local.aws_ecs_task_type[count.index + length(local.aws_ecs_app_image)]]
  cpu                      = local.aws_ecs_task_cpu[count.index + length(local.aws_ecs_app_image)]
  memory                   = local.aws_ecs_task_mem[count.index + length(local.aws_ecs_app_image)]
  execution_role_arn       = local.ecsTaskExecutionRole
  container_definitions    = sensitive(file("../../ansible/clone_repo/app/${var.app_repo_name}/${local.aws_ecs_task_json_definition_file[count.index]}"))
}

resource "aws_ecs_task_definition" "aws_ecs_task_ignore_definition" {
  count                    = var.aws_ecs_task_ignore_definition ? 1 : 0
  family                   = var.aws_ecs_task_name  != "" ? local.aws_ecs_task_name[count.index] : "${local.aws_ecs_task_name[count.index]}${count.index}"
  network_mode             = local.aws_ecs_task_network_mode[count.index]
  requires_compatibilities = [local.aws_ecs_task_type[count.index]]
  cpu                      = local.aws_ecs_task_cpu[count.index]
  memory                   = local.aws_ecs_task_mem[count.index]
  execution_role_arn       = local.ecsTaskExecutionRole
  container_definitions    = sensitive(jsonencode([
    {
      "name": var.aws_ecs_task_name != "" ? local.aws_ecs_task_name[count.index] : "${local.aws_ecs_task_name[count.index]}${count.index}",
      "image": "nginx:alpine",
      "essential": true,
      "portMappings": [
        {
          "containerPort": 80,
          "protocol": "tcp"
        }
      ]
    }
  ]))
  lifecycle {
    ignore_changes = [container_definitions]
  }
}

resource "aws_ecs_service" "ecs_service" {
  count            = var.aws_ecs_task_ignore_definition ? 0 : local.tasks_count
  name             = var.aws_ecs_service_name != "" ? "${var.aws_ecs_service_name}${count.index}" : "${var.aws_resource_identifier}-${count.index}-service"
  cluster          = aws_ecs_cluster.cluster.id
  task_definition  = local.tasks_arns[count.index]

  desired_count    = local.aws_ecs_node_count[count.index]
  launch_type      = var.aws_ecs_service_launch_type

  network_configuration {
    security_groups  = [aws_security_group.ecs_sg.id]
    subnets          = var.aws_selected_subnets
    assign_public_ip = var.aws_ecs_assign_public_ip
  }

  dynamic "load_balancer" {
    for_each = length(local.aws_ecs_container_port) > 0 ? [1] : []
    content {
      target_group_arn = aws_alb_target_group.lb_targets[count.index].id
      container_name   = var.aws_ecs_task_name != "" ? local.aws_ecs_task_name[count.index] : "${local.aws_ecs_task_name[count.index]}${count.index}"
      container_port   = local.aws_ecs_container_port[count.index]
    }
  }

  depends_on = [aws_alb_listener.lb_listener, aws_alb_listener.lb_listener_ssl]
}

resource "aws_ecs_service" "ecs_service_ignore_definition" {
  count            = var.aws_ecs_task_ignore_definition ? 1 : 0
  name             = var.aws_ecs_service_name != "" ? "${var.aws_ecs_service_name}${count.index}" : "${var.aws_resource_identifier}-${count.index}-service"
  cluster          = aws_ecs_cluster.cluster.id
  task_definition  = aws_ecs_task_definition.aws_ecs_task_ignore_definition[0].arn

  desired_count    = local.aws_ecs_node_count[count.index]
  launch_type      = var.aws_ecs_service_launch_type

  network_configuration {
    security_groups  = [aws_security_group.ecs_sg.id]
    subnets          = var.aws_selected_subnets
    assign_public_ip = var.aws_ecs_assign_public_ip
  }

  dynamic "load_balancer" {
    for_each = length(local.aws_ecs_container_port) > 0 ? [1] : []
    content {
      target_group_arn = aws_alb_target_group.lb_targets[count.index].id
      container_name   = var.aws_ecs_task_name != "" ? local.aws_ecs_task_name[count.index] : "${local.aws_ecs_task_name[count.index]}${count.index}"
      container_port   = local.aws_ecs_container_port[count.index]
    }
  }

  lifecycle {
    ignore_changes = [task_definition]
  }

  depends_on = [aws_alb_listener.lb_listener, aws_alb_listener.lb_listener_ssl]
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
  count = var.aws_ecs_task_execution_role != "" ? 1 : 0
  name  = var.aws_ecs_task_execution_role
}

resource "aws_iam_role" "ecsTaskExecutionRole" {
  count = var.aws_ecs_task_execution_role != "" ? 0 : 1
  name  = "${var.aws_resource_identifier}-ecs"
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "ecs-tasks.amazonaws.com"
        },
        "Action" : "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy_attachment" "ecsTaskExecutionRolePolicy" {
  count      = var.aws_ecs_task_execution_role != "" ? 0 : 1
  name       = "AmazonECSTaskExecutionRolePolicyAttachment"
  roles      = [aws_iam_role.ecsTaskExecutionRole[0].name]
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}