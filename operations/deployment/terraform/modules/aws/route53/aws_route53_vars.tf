variable "aws_r53_domain_name" {}
variable "aws_r53_sub_domain_name" {}
variable "aws_r53_root_domain_deploy" {}
variable "aws_r53_enable_cert" {}
variable "aws_elb_dns_name" {}
variable "aws_elb_zone_id" {}
variable "aws_elb_listen_port" {}
  # Certs
variable "aws_certificates_selected_arn" {}
variable "fqdn_provided" {}
variable "common_tags" {
    type = map
    default = {}
}