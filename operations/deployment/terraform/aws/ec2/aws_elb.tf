data "aws_elb_service_account" "main" {}

resource "aws_s3_bucket" "lb_access_logs" {
  bucket = var.lb_access_bucket_name
  force_destroy = true
  tags = {
    Name = var.lb_access_bucket_name
  }
}

resource "aws_s3_bucket_policy" "allow_access_from_another_account" {
  bucket = aws_s3_bucket.lb_access_logs.id
  policy = <<POLICY
{
  "Id": "Policy",
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:PutObject"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:s3:::${var.lb_access_bucket_name}/*",
      "Principal": {
        "AWS": [
          "${data.aws_elb_service_account.main.arn}"
        ]
      }
    }
  ]
}
POLICY
}

# Adding an allow all from ELB to EC2
resource "aws_security_group_rule" "incoming_elb" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = -1
  source_security_group_id = aws_security_group.elb_security_group.id
  security_group_id        = aws_security_group.ec2_security_group.id
}

# Adding ELB security group with full out
resource "aws_security_group" "elb_security_group" {
  name        = var.aws_elb_security_group_name != "" ? var.aws_elb_security_group_name : "SG for ${var.aws_resource_identifier} - ELB"
  description = "SG for ${var.aws_resource_identifier} - ELB"
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "${var.aws_resource_identifier}-elb"
  }
}

# Adding rules to accept incoming connections to the ELB
resource "aws_security_group_rule" "incoming_elb_ports" {
  count       = local.aws_ports_ammount
  type        = "ingress"
  from_port   = local.aws_elb_listen_port[count.index]
  to_port     = local.aws_elb_listen_port[count.index]
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = aws_security_group.elb_security_group.id
}

# Creating ELB with port mappings
resource "aws_elb" "vm_lb" {
  name               = var.aws_resource_identifier_supershort
  security_groups    = [aws_security_group.elb_security_group.id]
  availability_zones = [aws_instance.server.availability_zone]
  # TODO - ADD VPC Handling
  # availability_zones = var.create_vpc == "true" ? null : [aws_instance.server.availability_zone]
  # subnets            = var.create_vpc == "true" ? aws_subnet.public.*.id : null

  access_logs {
    bucket   = aws_s3_bucket.lb_access_logs.id
    interval = 60
  }

  dynamic "listener" {
    for_each = local.listener_for_each 

    content {
      instance_port      = local.aws_elb_app_port[listener.key]
      instance_protocol  = local.elb_app_protocol[listener.key]
      lb_port            = local.aws_elb_listen_port[listener.key]
      lb_protocol        = local.elb_listen_protocol[listener.key]
      ssl_certificate_id = local.aws_elb_arn
    }
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = var.aws_elb_healthcheck
    interval            = 30
  }

  instances                   = [aws_instance.server.id]
  cross_zone_load_balancing   = true
  idle_timeout                = 400
  connection_draining         = true
  connection_draining_timeout = 400

  tags = {
    Name = "${var.aws_resource_identifier_supershort}"
  }
}

output "lb_public_dns" {
  description = "Public DNS address of the LB"
  value       = aws_elb.vm_lb.dns_name
}

locals {

}

# TODO: Fix when a user only passes app_ports, the target length should be the same. 
# The main idea of the next block is to get what should be opened, mapped, and with which protocol.
locals {
  aws_elb_arn = var.aws_r53_enable_cert ? "${local.selected_arn}" : ""

  # Check if there is a cert available
  elb_ssl_available       = local.aws_elb_arn != "" ? true : false

  # Transform CSV values into arrays. ( Now variables will be called local.xx instead of var.xx )
  aws_elb_listen_port     = var.aws_elb_listen_port     != "" ? [for n in split(",", var.aws_elb_listen_port)     : tonumber(n)] : ( local.elb_ssl_available ? [443] : [80] )
  aws_elb_listen_protocol = var.aws_elb_listen_protocol != "" ? [for n in split(",", var.aws_elb_listen_protocol) : (n)] : ( local.elb_ssl_available ? ["ssl"] : ["tcp"] )
  aws_elb_app_port        = var.aws_elb_app_port        != "" ? [for n in split(",", var.aws_elb_app_port)        : tonumber(n)] : []
  aws_elb_app_protocol    = var.aws_elb_app_protocol    != "" ? [for n in split(",", var.aws_elb_app_protocol)    : (n)] : []

  # Store the lowest array length. (aws_elb_app_port will be at least 3000)
  aws_ports_ammount       = length(local.aws_elb_listen_port) < length(local.aws_elb_app_port) ? length(local.aws_elb_listen_port) : length(local.aws_elb_app_port)

  # Store the shortest array, and use that to generate ELB listeners. 
  listener_for_each       = length(local.aws_elb_listen_port) < length(local.aws_elb_app_port) ? local.aws_elb_listen_port : local.aws_elb_app_port
  # Check protocols ammounts
  aws_protos_ammount      = length(local.aws_elb_listen_protocol) < length(local.aws_elb_app_protocol) ? length(local.aws_elb_listen_protocol) : length(local.aws_elb_app_protocol)

  # If no protocols are defined for the app, set up the ammount of ports to be tcp.  
  elb_app_protocol        = length(local.aws_elb_app_protocol) < local.aws_ports_ammount ? [ for _ in range(local.aws_ports_ammount) : "tcp" ] : local.aws_elb_app_protocol
  # Same but for listen protocols, and if a cert is available, make them SSL
  elb_listen_protocol     = length(local.aws_elb_listen_protocol) < local.aws_ports_ammount ? ( local.elb_ssl_available ? 
    [ for _ in range(local.aws_ports_ammount) : "ssl" ] : [ for _ in range(local.aws_ports_ammount) : "tcp" ] ) : local.aws_elb_listen_protocol
}