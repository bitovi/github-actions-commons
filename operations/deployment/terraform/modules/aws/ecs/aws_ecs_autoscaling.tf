
resource "aws_appautoscaling_target" "ecs_target" {
  count              = var.aws_ecs_autoscaling_enable ? length(local.aws_aws_ecs_app_image) : 0
  max_capacity       = local.aws_ecs_autoscaling_max_nodes[count.index]
  min_capacity       = local.aws_ecs_autoscaling_min_nodes[count.index]
  resource_id        = "service/${aws_ecs_cluster.cluster.name}/${aws_ecs_service.aws-ecs-service.name[count.index]}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

locals {
  aws_ecs_autoscaling_max_nodes = var.aws_ecs_autoscaling_max_nodes != "" ? [for n in split(",", var.aws_ecs_autoscaling_max_nodes) : tonumber(n)] : [for _ in range(length(local.aws_aws_ecs_app_image)) : 2]
  aws_ecs_autoscaling_min_nodes = var.aws_ecs_autoscaling_min_nodes != "" ? [for n in split(",", var.aws_ecs_autoscaling_min_nodes) : tonumber(n)] : [for _ in range(length(local.aws_aws_ecs_app_image)) : 1]
  aws_ecs_autoscaling_max_mem   = var.aws_ecs_autoscaling_max_mem   != "" ? [for n in split(",", var.aws_ecs_autoscaling_max_mem)   : tonumber(n)] : [for _ in range(length(local.aws_aws_ecs_app_image)) : 80]
  aws_ecs_autoscaling_max_cpu   = var.aws_ecs_autoscaling_max_cpu   != "" ? [for n in split(",", var.aws_ecs_autoscaling_max_cpu)   : tonumber(n)] : [for _ in range(length(local.aws_aws_ecs_app_image)) : 80]
}

resource "aws_appautoscaling_policy" "ecs_policy_memory" {
  count              = var.aws_ecs_autoscaling_enable ? length(local.aws_aws_ecs_app_image) : 0
  name               = "${aws_ecs_service.aws-ecs-service.name[count.index]}-memory-autoscaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_target[count.index].resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target[count.index].scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target[count.index].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }

    target_value = local.aws_ecs_autoscaling_max_mem[count.index]
  }
}

resource "aws_appautoscaling_policy" "ecs_policy_cpu" {
  count              = var.aws_ecs_autoscaling_enable ? length(local.aws_aws_ecs_app_image) : 0
  name               = "${aws_ecs_service.aws-ecs-service.name[count.index]}-cpu-autoscaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_target[count.index].resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target[count.index].scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target[count.index].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value = local.aws_ecs_autoscaling_max_cpu[count.index]
  }
}