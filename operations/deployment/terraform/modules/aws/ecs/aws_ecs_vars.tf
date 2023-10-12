variable "aws_ecs_service_name" {}
variable "aws_ecs_cluster_name" {}
variable "aws_ecs_task_name" {}
variable "aws_ecs_task_execution_role" {}
variable "aws_ecs_task_json_definition_file" {}
variable "aws_ecs_task_cpu" {}
variable "aws_ecs_task_mem" {}
variable "aws_ecs_container_cpu" {}
variable "aws_ecs_container_mem" {}
variable "aws_ecs_node_count" {}
variable "aws_ecs_app_image" {}
variable "aws_ecs_image_path" {}
variable "aws_ecs_security_group_name" {}
variable "aws_ecs_assign_public_ip" {}
variable "aws_ecs_container_port" {}
variable "aws_ecs_lb_port" {}
variable "aws_ecs_lb_redirect_enable" {}
variable "aws_ecs_autoscaling_enable" {}
variable "aws_ecs_autoscaling_max_nodes" {}
variable "aws_ecs_autoscaling_min_nodes" {}
variable "aws_ecs_autoscaling_max_mem" {}
variable "aws_ecs_autoscaling_max_cpu" {}
variable "aws_ecs_cloudwatch_enable" {}
variable "aws_ecs_cloudwatch_lg_name" {}
variable "aws_ecs_cloudwatch_skip_destroy" {}
variable "aws_ecs_cloudwatch_retention_days" {}
variable "aws_certificates_selected_arn" {}
variable "aws_region_current_name" {}
variable "aws_resource_identifier" {}
variable "aws_resource_identifier_supershort" {}
variable "aws_selected_vpc_id" {}
variable "aws_selected_subnets" {}
variable "app_repo_name" {}