# AWS Load Balancer Wrapper Module

This module provides a unified interface for deploying either Classic ELB or Application Load Balancer (ALB) based on the `aws_lb_type` variable.

## Usage

```terraform
module "aws_lb" {
  source = "./modules/aws/aws_lb"
  
  # Choose load balancer type
  aws_lb_type = "alb"  # or "elb"
  
  # Common configuration for both ELB and ALB
  aws_elb_security_group_name        = "my-lb-sg"
  aws_elb_app_port                   = "3000"
  aws_elb_listen_port                = "80,443"
  aws_elb_healthcheck                = "HTTP:3000/"
  aws_elb_access_log_bucket_name     = "my-lb-logs-bucket"
  
  # ALB-specific options (ignored when using ELB)
  aws_alb_enable_waf                 = true
  aws_alb_subnets                    = ["subnet-123", "subnet-456"]
  
  # Required variables
  aws_vpc_selected_id                = "vpc-123"
  aws_instance_server_id             = "i-123"
  # ... other required variables
}
```

## Load Balancer Types

### Classic ELB (`aws_lb_type = "elb"`)
- Layer 4 load balancer
- Supports TCP, HTTP, HTTPS, SSL protocols
- Single availability zone deployment (using `aws_vpc_subnet_selected`)
- Legacy option but still supported

### Application Load Balancer (`aws_lb_type = "alb"`)
- Layer 7 load balancer
- HTTP/HTTPS only
- Multi-AZ deployment (using `aws_alb_subnets` or falls back to single subnet)
- Advanced routing capabilities
- WAF support (when `aws_alb_enable_waf = true`)
- Modern option with more features

## Variables

### Common Variables (used by both ELB and ALB)
- `aws_lb_type` - Type of load balancer: "elb" or "alb" (default: "elb")
- `aws_elb_security_group_name` - Security group name
- `aws_elb_app_port` - Application port(s) (comma-separated)
- `aws_elb_listen_port` - Listener port(s) (comma-separated)
- `aws_elb_healthcheck` - Health check configuration
- `aws_elb_access_log_bucket_name` - S3 bucket for access logs
- And other standard ELB variables...

### ALB-Specific Variables
- `aws_alb_enable_waf` - Enable AWS WAF v2 (boolean, default: false)
- `aws_alb_subnets` - List of subnet IDs for multi-AZ ALB deployment

## Outputs

### Common Outputs (available for both types)
- `aws_elb_dns_name` - DNS name of the load balancer
- `aws_elb_zone_id` - Route53 zone ID of the load balancer
- `lb_type` - Type of load balancer deployed

### ALB-Specific Outputs
- `alb_arn` - ARN of the ALB (empty if using ELB)
- `alb_target_group_arns` - ARNs of ALB target groups (empty if using ELB)

## Migration from ELB to ALB

To migrate from ELB to ALB, simply change:
```terraform
aws_lb_type = "alb"
```

And optionally add ALB-specific configuration:
```terraform
aws_alb_enable_waf = true
aws_alb_subnets    = ["subnet-1", "subnet-2"]  # For multi-AZ
```

## Notes

- When using ALB, ensure you have at least one public subnet
- ALB requires multiple subnets for high availability, but will fall back to single subnet if `aws_alb_subnets` is empty
- WAF is only available with ALB, not Classic ELB
- The module maintains backward compatibility with existing ELB configurations
