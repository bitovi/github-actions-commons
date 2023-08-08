resource "local_file" "ansible_inventor_no_efs" {
  count    = var.aws_efs_enable ? 0 : 1
  filename = format("%s/%s", abspath(path.root), "inventory.yaml")
  content  = <<-EOT
bitops_servers:
 hosts: ${var.aws_ec2_instance_ip}
 vars:
   ansible_ssh_user: ubuntu
   ansible_ssh_private_key_file: ${var.private_key_filename}
   app_repo_name: ${var.app_repo_name}
   app_install_root: ${var.app_install_root}
   resource_identifier: ${var.aws_resource_identifier}
   docker_remove_orphans: ${var.docker_remove_orphans}
EOT
}

data "aws_efs_file_system" "mount_efs" {
  count = var.aws_efs_enable ? 1 : 0
  file_system_id = var.aws_efs_fs_id
}

resource "local_file" "ansible_inventory_efs" {
  count    = var.aws_efs_enable ? 1 : 0
  filename = format("%s/%s", abspath(path.root), "inventory.yaml")
  content  = <<-EOT
bitops_servers:
 hosts: ${var.aws_ec2_instance_ip}
 vars:
   ansible_ssh_user: ubuntu
   ansible_ssh_private_key_file: ${var.private_key_filename}
   app_repo_name: ${var.app_repo_name}
   app_install_root: ${var.app_install_root}
   resource_identifier: ${var.aws_resource_identifier}
   docker_remove_orphans: ${var.docker_remove_orphans}
   mount_efs: true
   efs_url: ${data.aws_efs_file_system.mount_efs[0].dns_name}
   aws_efs_ec2_mount_point: ${var.aws_efs_ec2_mount_point}
   aws_efs_mount_target: ${var.aws_efs_mount_target != null ? var.aws_efs_mount_target : ""}
   docker_efs_mount_target: ${var.docker_efs_mount_target}
   EOT
}

resource "local_file" "efs-dotenv" {
  count    = var.aws_efs_enable ? 1 : 0
  filename = format("%s/%s", abspath(path.root), "efs.env")
  content  = <<-EOT
#### EFS
HOST_DIR="${var.app_install_root}/${var.app_repo_name}/${var.aws_efs_ec2_mount_point}"
TARGET_DIR="${var.docker_efs_mount_target}"
EOT
}