locals {
  # replica_destination: Checks whether a replica destination exists otherwise sets a default
  replica_destination  = var.aws_efs_replication_destination != "" ? var.aws_efs_replication_destination : data.aws_region.current.name
  #create_mount_targets = var.aws_efs_create || var.aws_efs_create_ha || var.aws_efs_create_mount_target ? true : false
  #create_sg            = var.aws_efs_create || local.create_mount_targets ? true : false
  #create_mt            = var.aws_efs_create_mount_target != null ? var.aws_efs_create_mount_target : local.create_sg ? true : false
}

data "aws_region" "current" {}

# Create EFS

resource "aws_efs_file_system" "efs" {
  count = var.aws_efs_create ? 1 : 0
  # File system
  creation_token = "${var.aws_resource_identifier}-vol"
  encrypted      = var.aws_efs_vol_encrypted
  kms_key_id     = var.aws_efs_kms_key_id 

  performance_mode                = var.aws_efs_performance_mode # generalPurpose / maxIO
  throughput_mode                 = var.aws_efs_throughput_mode  #- (Optional) Throughput mode for the file system. Defaults to bursting. Valid values: bursting, provisioned, or elastic. When using provisioned, also set provisioned_throughput_in_mibps.
  provisioned_throughput_in_mibps = var.aws_efs_throughput_speed # - (Optional) The throughput, measured in MiB/s, that you want to provision for the file system. Only applicable with throughput_mode set to provisioned.

  lifecycle_policy {
    transition_to_ia = var.aws_efs_transition_to_inactive
  }

  tags = {
    Name = "${var.aws_resource_identifier}-vol"
  }
}

resource "aws_efs_backup_policy" "efs_policy" {
  count          = var.aws_efs_enable_backup_policy ? 1 : 0
  file_system_id = data.aws_efs_file_system.efs.id

  backup_policy {
    status = "ENABLED"
  }
}

data "aws_efs_file_system" "efs" {
  file_system_id =  var.aws_efs_create ? aws_efs_file_system.efs[0].id : var.aws_efs_fs_id
}

resource "aws_efs_mount_target" "efs_mount_target_incoming" {
  count           = var.aws_efs_create_mount_target ? length(local.aws_efs_subnets) : 0
  file_system_id  = data.aws_efs_file_system.efs.id
  subnet_id       = local.aws_efs_subnets[count.index]
  security_groups = [aws_security_group.efs_security_group[0].id]
}

resource "aws_efs_replication_configuration" "efs_rep_config" {
  count                 = var.aws_efs_create_replica ? 1 : 0
  source_file_system_id = data.aws_efs_file_system.efs.id

  destination {
    region = local.replica_destination
  }
}

### Security groups

resource "aws_security_group" "efs_security_group" {
  count       = var.aws_efs_create_mount_target ? 1 : 0
  name        = var.aws_efs_security_group_name != null ? var.aws_efs_security_group_name : "SG for ${var.aws_resource_identifier} - EFS"
  description = "SG for ${var.aws_resource_identifier} - EFS"
  vpc_id      = var.aws_selected_vpc_id
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }
  tags = {
    Name = "${var.aws_resource_identifier}-efs"
  }
}

resource "aws_security_group_rule" "ingress_efs" {
  count             = var.aws_efs_create_mount_target && var.aws_efs_ingress_allow_all ? 1 : 0
  type              = "ingress"
  description       = "${var.aws_resource_identifier} - EFS Port"
  from_port         = 2049
  to_port           = 2049
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.efs_security_group[0].id
}

locals {
  aws_efs_allowed_security_groups = var.aws_efs_allowed_security_groups != null ? [for n in split(",", var.aws_efs_allowed_security_groups) : n] : []
  aws_efs_subnets = var.aws_efs_create_ha ? data.aws_subnets.selected_vpc_id[0].ids : [var.aws_selected_subnet_id]
}

resource "aws_security_group_rule" "ingress_efs_extras" {
  count                    = var.aws_efs_create_mount_target ? length(local.aws_efs_allowed_security_groups) : 0
  type                     = "ingress"
  description              = "${var.aws_resource_identifier} - EFS ingress extra SG"
  from_port                = 2049
  to_port                  = 2049
  protocol                 = "tcp"
  source_security_group_id = local.aws_efs_allowed_security_groups[count.index]
  security_group_id        = aws_security_group.efs_security_group[0].id
}

#resource "aws_db_subnet_group" "selected" {
#  name       = "${var.aws_resource_identifier}-efs"
#  subnet_ids = local.aws_efs_subnets
#  tags = {
#    Name = "${var.aws_resource_identifier}-efs"
#  }
#}

######
# Data sources from selected (Coming from VPC module)

data "aws_subnets" "selected_vpc_id"  {
  count = var.aws_selected_vpc_id != null ? 1 : 0
  filter {
    name   = "vpc-id"
    values = [var.aws_selected_vpc_id]
  }
#  filter {
#    name   = "availability-zone-id"
#    values = [var.aws_selected_az_list[count.index]]
#  }
}

data "aws_vpc" "selected" {
  count = var.aws_selected_vpc_id != null ? 1 : 0
  id    = var.aws_selected_vpc_id
}

output "aws_efs_fs_id" {
  value = data.aws_efs_file_system.efs.id
}

output "aws_replica_fs_id" {
  value = try(aws_efs_replication_configuration.efs_rep_config[0].destination[0].file_system_id,null)
}

output "aws_efs_sg_id" {
  value = try(aws_security_group.efs_security_group[0].id,null)
}