resource "local_sensitive_file" "private_key" {
  content         = tls_private_key.key.private_key_pem
  filename        = format("%s/%s/%s", abspath(path.root), ".ssh", "bitops-ssh-key.pem")
  file_permission = "0600"
}

resource "local_file" "ansible_inventory" {
  filename = format("%s/%s", abspath(path.root), "inventory.yaml")
  content  = <<-EOT
bitops_servers:
 hosts:
   ${aws_instance.server.public_ip}
 vars:
   ansible_ssh_user: ubuntu
   ansible_ssh_private_key_file: ${local_sensitive_file.private_key.filename}
   app_repo_name: ${var.app_repo_name}
   app_install_root: ${var.app_install_root}
   mount_efs: ${local.mount_efs}
   efs_url: ${local.efs_url}
   resource_identifier: ${var.aws_resource_identifier}
   application_mount_target: ${var.application_mount_target}
   efs_mount_target: ${var.efs_mount_target != null ? var.efs_mount_target : ""}
   data_mount_target: ${var.data_mount_target}
EOT
}