resource "local_file" "aws_ansible_inventory" {
    count = var.aws_ec2_instance_public_ip ? 1 : 0
    filename = format("%s/%s", abspath(path.root), "aws_ansible_inventory.tf")
    content  = templatefile(format("%s/%s", abspath(path.module), "aws_ansible_inventory.tmpl"), {
      efs_lines = var.enable_efs ? local.efs_lines : ""
    })
}

# Root module inputs
variable "env_aws_secret" {
  type        = string
  default     = ""
}

variable "aws_ec2_instance_create" {
  type        = bool
  default     = false
}
variable "aws_ec2_instance_public_ip" {
  type        = bool
  default     = false
}

variable "enable_efs" {
  type        = bool
  default     = "false"
}

locals {
   efs_lines = <<EOT
   mount_efs: $${local.mount_efs}
   efs_url: $${local.efs_url}
   aws_efs_ec2_mount_point: $${var.aws_efs_ec2_mount_point}
   aws_efs_mount_target: $${var.aws_efs_mount_target != null ? var.aws_efs_mount_target : ""}
   docker_efs_mount_target: $${var.docker_efs_mount_target}
   EOT
}