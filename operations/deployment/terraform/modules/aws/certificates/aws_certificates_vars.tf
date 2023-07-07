variable "aws_r53_create_root_cert" {}
variable "aws_r53_create_sub_cert" {}
variable "aws_r53_cert_arn" {}
# R53
variable "aws_r53_domain_name" {}
variable "aws_r53_sub_domain_name" {}
# Others
variable "aws_route53_zone_id" {
    type = list
}
variable "fqdn_provided" {}
variable "common_tags" {
    type = map
    default = {}
}