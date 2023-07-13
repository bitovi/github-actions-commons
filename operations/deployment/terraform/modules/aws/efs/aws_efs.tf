locals {
  # replica_destination: Checks whether a replica destination exists otherwise sets a default
  replica_destination  = var.aws_efs_replication_destination != null ? var.aws_efs_replication_destination : var.aws_region_current_name
}

# ---------------------CREATE--------------------------- #
resource "aws_efs_file_system" "efs" {
  # File system
  creation_token = "${var.aws_resource_identifier}-token-modular"
  encrypted      = true

  lifecycle_policy {
    transition_to_ia = var.aws_efs_transition_to_inactive
  }

  tags = {
    Name = "${var.aws_resource_identifier}-efs-modular"
  }
}

resource "aws_efs_backup_policy" "efs_policy" {
  count          = var.aws_efs_enable_backup_policy ? 1 : 0
  file_system_id = aws_efs_file_system.efs.id

  backup_policy {
    status = "ENABLED"
  }
}

resource "aws_efs_replication_configuration" "efs_rep_config" {
  count                 = var.aws_efs_create_replica ? 1 : 0
  source_file_system_id = aws_efs_file_system.efs.id

  destination {
    region = local.replica_destination
  }
}

resource "aws_security_group" "efs_security_group" {
  name   = var.aws_efs_security_group_name != "" ? var.aws_efs_security_group_name : "SG for ${var.aws_resource_identifier} - EFS"
  description = "SG for ${var.aws_resource_identifier} - EFS"
  vpc_id      = var.aws_vpc_id
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

resource "aws_security_group_rule" "efs_nfs_incoming_ports" {
  type              = "ingress"
  description       = "NFS from VPC"
  from_port         = 2049
  to_port           = 2049
  protocol          = "tcp"
  cidr_blocks       = [var.aws_vpc_cidr_block_whitelist]
  security_group_id = aws_security_group.efs_security_group.id
}

output "aws_security_group_efs_id" {
  value = aws_security_group.efs_security_group.id
}

output "aws_efs_fs_id" {
  value = aws_efs_file_system.efs.id
}