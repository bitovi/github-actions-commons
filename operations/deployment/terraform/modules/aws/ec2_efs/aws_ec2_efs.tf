locals {
  # user_zone_mapping: Create a zone mapping object list for all user specified zone_maps
  user_zone_mapping = var.aws_efs_zone_mapping != "" ? ({
    for k, val in var.aws_efs_zone_mapping : "${var.aws_region_current_name}${k}" => val
  }) : local.no_zone_mapping

  create_ec2_efs    = var.aws_efs_create || var.aws_efs_create_ha ? true : false
  # mount_target: Fall-Through variable that checks multiple layers of EFS zone map selection
  mount_target      = var.aws_efs_zone_mapping != "" ? local.user_zone_mapping : (var.aws_efs_create_ha ? var.ha_zone_mapping : var.ec2_zone_mapping != "" ? var.ec2_zone_mapping : local.no_zone_mapping)
  # mount_efs: Fall-Through variable that checks multiple layers of EFS creation and if any of them are active, sets creation to active.
  mount_efs         = var.aws_efs_mount_id != "" ? true : (local.create_ec2_efs ? true : false)
  # create_mount_targets: boolean on whether to create mount_targets
  create_mount_targets = var.aws_efs_create || var.aws_efs_create_ha ? local.mount_target : {}
}

data "aws_subnets" "vpc_subnets" {
  filter {
    name   = "vpc-id"
    values = [var.aws_selected_vpc_id]
  }
}

# Should we move this to EC2 ?
resource "aws_efs_mount_target" "efs_mount_target" {
  for_each        = local.create_mount_targets
  file_system_id  = var.aws_efs_fs_id
  subnet_id       = each.value["subnet_id"]
  security_groups = [var.aws_security_group_efs_id]
}

# TODO: Add check for EFS/EFSHA vs. Provided Mount id.

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

#output "mount_efs" {
#  value = local.mount_efs
#}


  source = "../modules/aws/ec2_efs"
  count  = var.aws_ec2_instance_create ? var.aws_efs_mount_id != "" ? 1 : 0 : 0
  # EFS
  aws_efs_create                  = var.aws_efs_create
  aws_efs_create_ha               = var.aws_efs_create_ha
  aws_efs_mount_id                = var.aws_efs_mount_id
  aws_efs_zone_mapping            = var.aws_efs_zone_mapping
  aws_efs_ec2_mount_point         = var.aws_efs_ec2_mount_point
  # Other
  ha_zone_mapping                 = module.vpc.ha_zone_mapping
  ec2_zone_mapping                = module.vpc.ec2_zone_mapping
  # Docker
  docker_efs_mount_target         = var.docker_efs_mount_target
  # Data inputs
  aws_region_current_name         = module.vpc.aws_region_current_name #
  aws_security_group_efs_id       = module.efs[0].aws_security_group_efs_id
  aws_efs_fs_id                   = module.efs[0].aws_efs_fs_id
  # Others
  common_tags                     = local.default_tags
  # Not exposed
  app_install_root                = var.app_install_root
  app_repo_name                   = var.app_repo_name
  # Dependencies
  depends_on = [module.efs]

  variable "aws_efs_create" {}
variable "aws_efs_create_ha" {}
variable "aws_efs_mount_id" {}