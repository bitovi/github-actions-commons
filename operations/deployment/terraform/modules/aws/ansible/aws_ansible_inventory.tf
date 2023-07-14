resource "local_file" "ansible_inventor_no_efs" {
  count    = var.aws_efs_enable ? 0 : 1
  filename = format("%s/%s", abspath(path.root), "inventory.yaml")
  content  = <<-EOT
bitops_servers:
 hosts: BITOPS_EC2_PUBLIC_IP
 vars:
   ansible_ssh_user: ubuntu
   ansible_ssh_private_key_file: bitops-ssh-key.pem
   app_repo_name: ${var.app_repo_name}
   app_install_root: ${var.app_install_root}
   resource_identifier: ${var.aws_resource_identifier}
EOT
}

resource "local_file" "ansible_inventory_efs" {
  count    = var.aws_efs_enable ? 1 : 0
  filename = format("%s/%s", abspath(path.root), "inventory.yaml")
  content  = <<-EOT
bitops_servers:
 hosts: BITOPS_EC2_PUBLIC_IP
 vars:
   ansible_ssh_user: ubuntu
   ansible_ssh_private_key_file: bitops-ssh-key.pem
   app_repo_name: ${var.app_repo_name}
   app_install_root: ${var.app_install_root}
   resource_identifier: ${var.aws_resource_identifier}
   mount_efs: true
   efs_url: ${var.aws_ec2_efs_url}
   aws_efs_ec2_mount_point: ${var.aws_efs_ec2_mount_point}
   aws_efs_mount_target: ${var.aws_efs_mount_target != null ? var.aws_efs_mount_target : ""}
   docker_efs_mount_target: ${var.docker_efs_mount_target}
   EOT
}