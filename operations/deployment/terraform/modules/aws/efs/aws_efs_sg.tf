resource "aws_security_group" "efs_security_group" {
  name   = var.aws_efs_security_group_name != "" ? var.aws_efs_security_group_name : "SG for ${var.aws_resource_identifier} - EFS"
  description = "SG for ${var.aws_resource_identifier} - EFS"
  vpc_id      = var.aws_vpc_default_id
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "${var.aws_resource_identifier}-efs-sg"
  }
}

# Will create a whitelist for the whole VPC - Maybe a flag here?
resource "aws_security_group_rule" "efs_ingress_ports" {
  count             = var.aws_ec2_instance_create ? 0 : 1
  type              = "ingress"
  description       = "HTTP from VPC"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.efs_security_group.id
}

resource "aws_security_group_rule" "efs_tls_incoming_ports" {
  count             = var.aws_ec2_instance_create ? 0 : 1
  type              = "ingress"
  description       = "TLS from VPC"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.efs_security_group.id
}

# Whitelist the EFS security group for the EC2 Security Group
resource "aws_security_group_rule" "ingress_ec2_to_efs" {
  count                    = var.aws_ec2_instance_create ? 1 : 0
  type                     = "ingress"
  description              = "${var.aws_resource_identifier} - SSL EFS"
  from_port                = 443
  to_port                  = 443
  protocol                 = "all"
  source_security_group_id = data.aws_security_group.efs_security_group[0].id
  security_group_id        = var.aws_security_group_ec2_sg_id
}

resource "aws_security_group_rule" "ingress_efs_to_ec2" {
  count                    = var.aws_ec2_instance_create ? 1 : 0
  type                     = "ingress"
  description              = "${var.aws_resource_identifier} - NFS EFS"
  from_port                = 80
  to_port                  = 80
  protocol                 = "all"
  source_security_group_id = var.aws_security_group_ec2_sg_id
  security_group_id        = data.aws_security_group.efs_security_group[0].id
}

resource "aws_security_group_rule" "mount_ingress_ec2_to_efs" {
  count                    = var.aws_efs_mount_security_group_id != null ? 1 : 0
  type                     = "ingress"
  description              = "${var.aws_resource_identifier} - EFS"
  from_port                = 443
  to_port                  = 443
  protocol                 = "all"
  source_security_group_id = var.aws_efs_mount_security_group_id
  security_group_id        = var.aws_security_group_ec2_sg_id
}

resource "aws_security_group_rule" "mount_ingress_efs_to_ec2" {
  count                    = var.aws_efs_mount_security_group_id != null ? 1 : 0
  type                     = "ingress"
  description              = "${var.aws_resource_identifier} - NFS EFS"
  from_port                = 443
  to_port                  = 443
  protocol                 = "all"
  source_security_group_id = var.aws_security_group_ec2_sg_id
  security_group_id        = var.aws_efs_mount_security_group_id
}


