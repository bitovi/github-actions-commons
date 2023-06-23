locals {
  # replica_destination: Checks whether a replica destination exists otherwise sets a default
  replica_destination  = var.aws_efs_replication_destination != null ? var.aws_efs_replication_destination : data.aws_region.current.name
  # create_efs: boolean, checks whether to create an EFS or not
  create_efs           = var.aws_efs_create || var.aws_efs_create_ha ? true : false 
}

# ---------------------CREATE--------------------------- #
resource "aws_efs_file_system" "efs" {
  # File system
  count          = local.create_efs ? 1 : 0
  creation_token = "${var.aws_resource_identifier}-token-modular"
  encrypted      = true

  lifecycle_policy {
    transition_to_ia = var.aws_efs_transition_to_inactive
  }

#  lifecycle {
#    prevent_destroy  = true
#  }

  tags = {
    Name = "${var.aws_resource_identifier}-efs-modular"
  }
}

resource "aws_security_group" "efs_security_group" {
  count  = local.create_efs ? 1 : 0
  name   = var.aws_efs_security_group_name != "" ? var.aws_efs_security_group_name : "SG for ${var.aws_resource_identifier} - EFS"
  description = "SG for ${var.aws_resource_identifier} - EFS"
  vpc_id      = data.aws_vpc.default.id
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

resource "aws_security_group_rule" "efs_ingress_ports" {
  count  = local.create_efs ? 1 : 0
  type        = "ingress"
  description = "HTTP from VPC"
  from_port   = 80
  to_port     = 80
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = aws_security_group.efs_security_group[0].id
}

resource "aws_security_group_rule" "efs_tls_incoming_ports" {
  count  = local.create_efs ? 1 : 0
  type        = "ingress"
  description = "TLS from VPC"
  from_port   = 443
  to_port     = 443
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = aws_security_group.efs_security_group[0].id
}

resource "aws_efs_backup_policy" "efs_policy" {
  count          = var.aws_efs_enable_backup_policy && local.create_efs ? 1 : 0
  file_system_id = aws_efs_file_system.efs[0].id

  backup_policy {
    status = "ENABLED"
  }
}

resource "aws_efs_replication_configuration" "efs_rep_config" {
  count                 = var.aws_efs_create_replica && local.create_efs ? 1 : 0
  source_file_system_id = aws_efs_file_system.efs[0].id

  destination {
    region = local.replica_destination
  }
}