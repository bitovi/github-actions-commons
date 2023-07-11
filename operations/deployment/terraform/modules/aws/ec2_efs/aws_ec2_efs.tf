locals {
  # user_zone_mapping: Create a zone mapping object list for all user specified zone_maps
  user_zone_mapping = var.aws_efs_zone_mapping != null ? ({
    for k, val in var.aws_efs_zone_mapping : "${var.aws_region_current_name}${k}" => val
  }) : local.no_zone_mapping

  create_ec2_efs    = var.aws_efs_create || var.aws_efs_create_ha ? true : false
  # mount_target: Fall-Through variable that checks multiple layers of EFS zone map selection
  mount_target      = var.aws_efs_zone_mapping != null ? local.user_zone_mapping : (var.aws_efs_create_ha ? var.ha_zone_mapping : (length(var.ec2_zone_mapping) > 0 ? var.ec2_zone_mapping : local.no_zone_mapping))
  # mount_efs: Fall-Through variable that checks multiple layers of EFS creation and if any of them are active, sets creation to active.
  mount_efs         = var.aws_efs_mount_id != null ? true : (local.create_ec2_efs ? true : false)
  # create_mount_targets: boolean on whether to create mount_targets
  create_mount_targets = var.aws_efs_create || var.aws_efs_create_ha ? local.mount_target : {}
}

resource "aws_efs_mount_target" "efs_mount_target" {
  for_each        = local.create_mount_targets
  file_system_id  = data.aws_efs_file_system.efs[0].id
  subnet_id       = each.value["subnet_id"]
  security_groups = [var.aws_elb_target_sg_id]
}

data "aws_security_group" "efs_security_group" {
  count  = local.create_ec2_efs ? 1 : 0
  filter {
    name   = "tag:Name"
    values = ["${var.aws_resource_identifier}-efs-sg"]
  }
}

data "aws_efs_file_system" "efs" {
  count  = local.create_ec2_efs ? 1 : 0
  tags = {
    Name = "${var.aws_resource_identifier}-efs-modular"
  }
}

# Whitelist the EFS security group for the EC2 Security Group
resource "aws_security_group_rule" "ingress_ec2_to_efs" {
  count                    = local.create_ec2_efs ? 1 : 0
  type                     = "ingress"
  description              = "${var.aws_resource_identifier} - SSL EFS"
  from_port                = 443
  to_port                  = 443
  protocol                 = "all"
  source_security_group_id = var.aws_elb_target_sg_id
  security_group_id        = var.aws_security_group_ec2_sg_id
}

resource "aws_security_group_rule" "ingress_efs_to_ec2" {
  count                    = local.create_ec2_efs ? 1 : 0
  type                     = "ingress"
  description              = "${var.aws_resource_identifier} - NFS EFS"
  from_port                = 80
  to_port                  = 80
  protocol                 = "all"
  source_security_group_id = var.aws_security_group_ec2_sg_id
  security_group_id        = var.aws_elb_target_sg_id
}
# ----------------------------------------------------- #

# ---------------------MOUNT--------------------------- #
data "aws_efs_file_system" "mount_efs" {
  count          = var.aws_efs_mount_id != null ? 1 : 0
  file_system_id = var.aws_efs_mount_id
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

resource "local_file" "efs-dotenv" {
  count    = local.create_ec2_efs ? 1 : 0
  filename = format("%s/%s", abspath(path.root), "efs.env")
  content  = <<-EOT
#### EFS
HOST_DIR="${var.app_install_root}/${var.app_repo_name}/${var.aws_efs_ec2_mount_point}"
TARGET_DIR="${var.docker_efs_mount_target}"
EOT
}

locals {
  create_efs_url = local.create_ec2_efs ? data.aws_efs_file_system.efs[0].dns_name : ""
  mount_efs_url  = var.aws_efs_mount_id != null ? data.aws_efs_file_system.mount_efs[0].dns_name : ""
  efs_url        = local.create_efs_url != "" ? local.create_efs_url : local.mount_efs_url

  # no_zone_mapping: Creates a empty zone mapping object list
  no_zone_mapping  = { "" : { "subnet_id" : "", "security_groups" : [""] } }
}

output "mount_efs" {
  value = local.mount_efs
}

output "efs_url" {
  value = local.efs_url
}