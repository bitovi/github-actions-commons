# ELB Module (Classic Load Balancer)
module "elb" {
  source = "../elb"
  count  = var.aws_lb_type == "elb" ? 1 : 0

  # Pass all ELB variables
  aws_elb_security_group_name        = var.aws_elb_security_group_name
  aws_elb_app_port                   = var.aws_elb_app_port
  aws_elb_app_protocol               = var.aws_elb_app_protocol
  aws_elb_listen_port                = var.aws_elb_listen_port
  aws_elb_listen_protocol            = var.aws_elb_listen_protocol
  aws_elb_healthcheck                = var.aws_elb_healthcheck
  aws_elb_access_log_bucket_name     = var.aws_elb_access_log_bucket_name
  aws_elb_access_log_expire          = var.aws_elb_access_log_expire
  aws_instance_server_az             = var.aws_instance_server_az
  aws_vpc_selected_id                = var.aws_vpc_selected_id
  aws_vpc_subnet_selected            = var.aws_vpc_subnet_selected
  aws_instance_server_id             = var.aws_instance_server_id
  aws_certificates_selected_arn      = var.aws_certificates_selected_arn
  aws_elb_target_sg_id               = var.aws_elb_target_sg_id
  aws_resource_identifier            = var.aws_resource_identifier
  aws_resource_identifier_supershort = var.aws_resource_identifier_supershort
}

# ALB Module (Application Load Balancer)
module "alb" {
  source = "../alb"
  count  = var.aws_lb_type == "alb" ? 1 : 0

  # Pass all ALB variables (using ELB variable names for consistency)
  aws_elb_security_group_name        = var.aws_elb_security_group_name
  aws_elb_app_port                   = var.aws_elb_app_port
  aws_elb_app_protocol               = var.aws_elb_app_protocol
  aws_elb_listen_port                = var.aws_elb_listen_port
  aws_elb_listen_protocol            = var.aws_elb_listen_protocol
  aws_elb_healthcheck                = var.aws_elb_healthcheck
  aws_elb_access_log_bucket_name     = var.aws_elb_access_log_bucket_name
  aws_elb_access_log_expire          = var.aws_elb_access_log_expire
  aws_instance_server_az             = var.aws_instance_server_az
  aws_vpc_selected_id                = var.aws_vpc_selected_id
  aws_vpc_subnet_selected            = var.aws_vpc_subnet_selected
  aws_instance_server_id             = var.aws_instance_server_id
  aws_certificates_selected_arn      = var.aws_certificates_selected_arn
  aws_elb_target_sg_id               = var.aws_elb_target_sg_id
  aws_resource_identifier            = var.aws_resource_identifier
  aws_resource_identifier_supershort = var.aws_resource_identifier_supershort
  # ALB specific variables
  aws_alb_enable_waf                 = var.aws_alb_enable_waf
  aws_alb_subnets                    = var.aws_alb_subnets
}

# Unified outputs that work regardless of LB type
output "aws_elb_dns_name" {
  description = "DNS name of the load balancer"
  value       = var.aws_lb_type == "elb" ? try(module.elb[0].aws_elb_dns_name, "") : try(module.alb[0].aws_elb_dns_name, "")
}

output "aws_elb_zone_id" {
  description = "Zone ID of the load balancer"
  value       = var.aws_lb_type == "elb" ? try(module.elb[0].aws_elb_zone_id, "") : try(module.alb[0].aws_elb_zone_id, "")
}

# Additional outputs for ALB-specific features
output "alb_arn" {
  description = "ARN of the ALB (empty if using ELB)"
  value       = var.aws_lb_type == "alb" ? try(module.alb[0].alb_arn, "") : ""
}

output "alb_target_group_arns" {
  description = "ARNs of ALB target groups (empty if using ELB)"
  value       = var.aws_lb_type == "alb" ? try(module.alb[0].alb_target_group_arns, []) : []
}

output "lb_type" {
  description = "Type of load balancer deployed"
  value       = var.aws_lb_type
}
