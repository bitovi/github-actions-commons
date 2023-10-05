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

#resource "aws_iam_role" "ecsTaskExecutionRole" {
#  name               = "${var.aws_resource_identifier}-Role"
#  assume_role_policy = "${data.aws_iam_policy_document.assume_role_policy.json}"
#}
#
#data "aws_iam_policy_document" "assume_role_policy" {
#  statement {
#    actions = ["sts:AssumeRole"]
#
#    principals {
#      type        = "Service"
#      identifiers = ["ecs-tasks.amazonaws.com"]
#    }
#  }
#}
#
#resource "aws_iam_role_policy_attachment" "ecsTaskExecutionRole_policy" {
#  role       = aws_iam_role.ecsTaskExecutionRole.name
#  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
#}

#resource "aws_ecs_service" "ecs_service_no_lb" {
#  name             = var.aws_ecs_service_name != "" ? var.aws_ecs_service_name : "${var.aws_resource_identifier}-service"
#  cluster          = aws_ecs_cluster.cluster.id
#  task_definition  = aws_ecs_task_definition.ecs_task.arn
#  desired_count    = var.aws_ecs_node_count
#  assign_public_ip = var.aws_ecs_assign_public_ip
#  launch_type      = "FARGATE"
#
#  network_configuration {
#    security_groups  = [aws_security_group.ecs_sg.id]
#    subnets          = var.aws_selected_subnets
#    assign_public_ip = true
#  }
#
#  depends_on = [aws_lb_listener.hello_world]
#}



locals {
  aws_ecs_task_name      = var.aws_ecs_task_name != "" ? var.aws_ecs_task_name : "${var.aws_resource_identifier}-app"
  aws_ecs_container_port = var.aws_ecs_container_port# != "" ? [for n in split(",", var.aws_ecs_container_port) : tonumber(n)] : []
  aws_ecs_lb_port        = var.aws_ecs_lb_port != "" ?  var.aws_ecs_lb_port : local.aws_ecs_container_port #      [for n in split(",", var.aws_ecs_lb_port)        : tonumber(n)] : local.aws_ecs_container_port
}

# Network part
resource "aws_security_group" "ecs_sg" {
  name        = var.aws_ecs_security_group_name != "" ? var.aws_ecs_security_group_name : "SG for ${var.aws_resource_identifier} ECS"
  description = "SG for ${var.aws_resource_identifier} - ${local.aws_ecs_task_name} - ECS"
  vpc_id      = var.aws_selected_vpc_id
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "${var.aws_resource_identifier}-ecs-sg"
  }
}

resource "aws_security_group_rule" "incoming_ecs_ports" {
 # count             = length(local.aws_ecs_container_port)
  type              = "ingress"
  from_port         = local.aws_ecs_container_port#[count.index]
  to_port           = local.aws_ecs_container_port#[count.index]
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.ecs_sg.id
}

resource "aws_security_group_rule" "incoming_alb" {
  #count                    = length(local.aws_ecs_container_port)
  type                     = "ingress"
  from_port                = local.aws_ecs_container_port#[count.index]
  to_port                  = local.aws_ecs_container_port#[count.index]
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.ecs_lb_sg.id
  security_group_id        = aws_security_group.ecs_sg.id
}


### ALB --- Make this optional -- Using ALB name intentionally. (To make clear is an A LB)

resource "aws_alb" "ecs_lb" {
  name            = var.aws_resource_identifier_supershort
  subnets         = var.aws_selected_subnets
  security_groups = [aws_security_group.ecs_lb_sg.id]

  tags = {
    Name = "${var.aws_resource_identifier_supershort}"
  }
}

resource "aws_alb_target_group" "lb_targets" {
  #count       = length(local.aws_ecs_container_port)
  name        = "${var.aws_resource_identifier_supershort}"
  port        = local.aws_ecs_container_port#[count.index]
  protocol    = "HTTP"
  vpc_id      = var.aws_selected_vpc_id
  target_type = "ip"

  lifecycle {
    replace_triggered_by = [aws_security_group.ecs_sg]
  }
}

# Redirect all traffic from the ALB to the target group
resource "aws_alb_listener" "lb_listener" {
  #count             = length(local.aws_ecs_lb_port)
  load_balancer_arn = "${aws_alb.ecs_lb.id}"
  port              = local.aws_ecs_lb_port#[count.index]
  protocol          = "HTTP"

  default_action {
#    target_group_arn = aws_alb_target_group.lb_targets[count.index].id
    target_group_arn = aws_alb_target_group.lb_targets.id
    type             = "forward"
  }
}

resource "aws_security_group" "ecs_lb_sg" {
  name        = var.aws_ecs_security_group_name != "" ? "${var.aws_ecs_security_group_name}-lb" : "SG for ${var.aws_resource_identifier} ECS LB"
  description = "SG for ${var.aws_resource_identifier} - ${local.aws_ecs_task_name} ECS Load Balancer"
  vpc_id      = var.aws_selected_vpc_id

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "${var.aws_resource_identifier}-ecs-lb-sg"
  }
}

resource "aws_security_group_rule" "incoming_ecs_lb_ports" {
  #count       = length(local.aws_ecs_lb_port)
  type        = "ingress"
  from_port   = local.aws_ecs_lb_port#[count.index]
  to_port     = local.aws_ecs_container_port#[count.index]
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = aws_security_group.ecs_lb_sg.id
}

output "load_balancer_dns" {
  value = aws_alb.ecs_lb.dns_name
}