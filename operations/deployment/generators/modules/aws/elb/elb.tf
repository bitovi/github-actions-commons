resource "local_file" "aws_elb" {
    filename = format("%s/%s", abspath(path.root), "aws_elb.tf")
    content  = templatefile(format("%s/%s", abspath(path.module), "aws_elb.tmpl"), {
      elb_resource_string = var.aws_r53_enable_cert ? "vm_lb_ssl" : "vm_lb"
      cert_string = var.aws_r53_enable_cert ? "$${local.selected_arn}" : ""
    })
}

# Root module inputs
variable "aws_r53_enable_cert" {
  type        = bool
  default     = false
}