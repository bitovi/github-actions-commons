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

output "aws_security_group_efs_id" {
  value = aws_security_group.efs_security_group.id
}