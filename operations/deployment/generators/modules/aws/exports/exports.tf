resource "local_file" "aws_dotenv_secretmanager" {
    count = var.env_aws_secret != "" ? 1 : 0
    filename = format("%s/%s", abspath(path.root), "aws_dotenv_secretmanager.tf")
    content = file(format("%s/%s", abspath(path.module), "aws_dotenv_secretmanager.tmpl"))
}

# Root module inputs
variable "env_aws_secret" {
  type        = string
  default     = ""
}
