resource "local_file" "aws_dotenv_secretmanager" {
    filename = format("%s/%s", abspath(path.root), "aws_dotenv_secretmanager.tf")
    content = file(format("%s/%s", abspath(path.module), "aws_dotenv_secretmanager.tmpl"))
}

resource "local_file" "aws_dotenv_tf" {
    filename = format("%s/%s", abspath(path.root), "aws_dotenv_tf.tf")
    content  = templatefile(format("%s/%s", abspath(path.module), "aws_dotenv_tf.tmpl"), {
      aws_instance_url_string = var.aws_ec2_instance_create ? "$${aws_instance.server.public_dns}" : ""
      host_dir_string         = var.aws_efs_create || var.aws_efs_create_ha ? "$${aws_efs_ec2_mount_point}" : ""
      target_dir_string       = var.aws_efs_create || var.aws_efs_create_ha ? "$${docker_efs_mount_target}" : ""
    })
}

# Root module inputs
variable "aws_ec2_instance_create" {
  type        = bool
  default     = false
}

variable "aws_efs_create" {
  type        = bool
  default     = "false"
}
variable "aws_efs_create_ha" {
  type        = bool
  default     = "false"
}