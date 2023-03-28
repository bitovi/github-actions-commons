resource "local_file" "aws_route53" {
    filename = format("%s/%s", abspath(path.root), "aws_route53.tf")
    content  = templatefile(format("%s/%s", abspath(path.module), "aws_route53.tmpl"), {
      elb_resource_string = var.aws_r53_enable_cert ? "vm_lb_ssl" : "vm_lb"
      r53_protocol_string = var.aws_r53_enable_cert ? "local.selected_arn != \"" ? "https://\"" : "\"http://\"" : "\"http://\""
    })
}

# Root module inputs
variable "aws_r53_enable_cert" {
  type        = bool
  default     = false
}