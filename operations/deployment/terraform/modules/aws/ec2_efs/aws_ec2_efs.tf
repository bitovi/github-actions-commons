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
  file_system_id  = var.aws_efs_fs_id
  subnet_id       = each.value["subnet_id"]
  security_groups = [var.aws_security_group_efs_id]
}

#data "aws_efs_file_system" "efs" {
#  count  = local.create_ec2_efs ? 1 : 0
#  tags = {
#    Name = "${var.aws_resource_identifier}-efs-modular"
#  }
#}
#
## We can remove this exposing the security group from EFS 
#data "aws_security_group" "efs_security_group" {
#  filter {
#    name   = "tag:Name"
#    values = ["${var.aws_resource_identifier}-efs-sg"]
#  }
#}

# TODO: Add check for EFS/EFSHA vs. Provided Mount id.

data "aws_efs_file_system" "mount_efs" {
  file_system_id = var.aws_efs_mount_id != null ? var.aws_efs_mount_id : var.aws_efs_fs_id
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
  # no_zone_mapping: Creates a empty zone mapping object list
  no_zone_mapping  = { "" : { "subnet_id" : "", "security_groups" : [""] } }
}

output "mount_efs" {
  value = local.mount_efs
}

#output "efs_url" {
#  value = try(data.aws_efs_file_system.efs[0].dns_name,data.aws_efs_file_system.mount_efs[0].dns_name)
#}

output "efs_url" {
  value = data.aws_efs_file_system.mount_efs.dns_name
}