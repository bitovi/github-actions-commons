resource "local_file" "aws_elb" {
    filename = format("%s/%s", abspath(path.root), "aws_elb.tf")
    content  = templatefile(format("%s/%s", abspath(path.module), "aws_elb.tmpl"), {
      aws_elb_arn = local.aws_elb_arn
  })
}

# Root module inputs
variable "aws_r53_enable_cert" {
  type        = bool
  default     = false
}
# Local definitions for template
locals {
  aws_elb_arn = var.aws_r53_enable_cert ? "local.selected_arn" : ""
}