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

data "aws_security_group" "efs_security_group" {
  filter {
    name   = "tag:Name"
    values = ["${var.aws_resource_identifier}-efs-sg"]
  }
  depends_on = [ aws_security_group.efs_security_group ]
}

#data "aws_efs_file_system" "efs" {
#  count  = local.create_ec2_efs ? 1 : 0
#  tags = {
#    Name = "${var.aws_resource_identifier}-efs-modular"
#  }
#}
#
#data "aws_efs_file_system" "mount_efs" {
#  count          = var.aws_efs_mount_id != null ? 1 : 0
#  file_system_id = var.aws_efs_mount_id
#}


# Will create a whitelist for the whole VPC - Maybe a flag here?
resource "aws_security_group_rule" "efs_http_ingress_ports" {
  #count             = var.aws_ec2_instance_create ? 0 : 1
  type              = "ingress"
  description       = "HTTP from VPC"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  #cidr_blocks       = [var.aws_ec2_vpc_cidr_block]
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = data.aws_security_group.efs_security_group.id
}

resource "aws_security_group_rule" "efs_tls_incoming_ports" {
  #count             = var.aws_ec2_instance_create ? 0 : 1
  type              = "ingress"
  description       = "TLS from VPC"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = data.aws_security_group.efs_security_group.id
}

resource "aws_security_group_rule" "efs_nfs_incoming_ports" {
  #count             = var.aws_ec2_instance_create ? 0 : 1
  type              = "ingress"
  description       = "NFS from VPC"
  from_port         = 2049
  to_port           = 2049
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = data.aws_security_group.efs_security_group.id
}

# Whitelist the EFS security group for the EC2 Security Group
resource "aws_security_group_rule" "ingress_ec2_to_efs" {
  count                    = var.aws_ec2_instance_create ? 1 : 0
  type                     = "ingress"
  description              = "${var.aws_resource_identifier} - NFS EFS"
  from_port                = 0
  to_port                  = 0
  protocol                 = "all"
  source_security_group_id = data.aws_security_group.efs_security_group.id
  security_group_id        = var.aws_security_group_ec2_sg_id
}

resource "aws_security_group_rule" "ingress_efs_to_ec2" {
  count                    = var.aws_ec2_instance_create ? 1 : 0
  type                     = "ingress"
  description              = "${var.aws_resource_identifier} - NFS EFS"
  from_port                = 0
  to_port                  = 0
  protocol                 = "all"
  source_security_group_id = var.aws_security_group_ec2_sg_id
  security_group_id        = data.aws_security_group.efs_security_group.id
}

#resource "aws_security_group_rule" "mount_ingress_ec2_to_efs" {
#  count                    = var.aws_efs_mount_security_group_id != null ? 1 : 0
#  type                     = "ingress"
#  description              = "${var.aws_resource_identifier} - EFS"
#  from_port                = 443
#  to_port                  = 443
#  protocol                 = "all"
#  source_security_group_id = var.aws_efs_mount_security_group_id
#  security_group_id        = var.aws_security_group_ec2_sg_id
#}
#
#resource "aws_security_group_rule" "mount_ingress_efs_to_ec2" {
#  count                    = var.aws_efs_mount_security_group_id != null ? 1 : 0
#  type                     = "ingress"
#  description              = "${var.aws_resource_identifier} - NFS EFS"
#  from_port                = 443
#  to_port                  = 443
#  protocol                 = "all"
#  source_security_group_id = var.aws_security_group_ec2_sg_id
#  security_group_id        = var.aws_efs_mount_security_group_id
#}
#

