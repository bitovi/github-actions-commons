data "aws_security_group" "ec2_security_group" {
  id = aws_security_group.ec2_security_group.id
}

resource "aws_security_group" "ec2_security_group" {
  name        = var.aws_ec2_security_group_name != "" ? var.aws_ec2_security_group_name : "SG for ${var.aws_resource_identifier} - EC2"
  description = "SG for ${var.aws_resource_identifier} - EC2"
  vpc_id      = data.aws_vpc.default.id
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "${var.aws_resource_identifier}-ec2-sg"
  }
}

# This is needed for Ansible to connect
resource "aws_security_group_rule" "ingress_ssh" {
  type        = "ingress"
  description = "SSH"
  from_port   = 22
  to_port     = 22
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = aws_security_group.ec2_security_group.id
}

resource "aws_security_group_rule" "incoming_ports" {
  count       = length(local.aws_ec2_port_list) != 0 ? length(local.aws_ec2_port_list) : 0
  type        = "ingress"
  from_port   = local.aws_ec2_port_list[count.index]
  to_port     = local.aws_ec2_port_list[count.index]
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = aws_security_group.ec2_security_group.id
}

locals {
  aws_ec2_port_list = var.aws_ec2_port_list != "" ? [for n in split(",", var.aws_ec2_port_list) : tonumber(n)] : []
}

output "aws_security_group_ec2_sg_name" {
  value = data.aws_security_group.ec2_security_group.name
}
output "aws_security_group_ec2_sg_id" {
  value = data.aws_security_group.ec2_security_group.id
}