module "aws_certificates" {
  source = "../../modules/aws/certificates"
  count  = var.aws_r53_enable_cert ? 1 : 0
  # Cert
  aws_r53_create_root_cert = var.aws_r53_create_root_cert
  aws_r53_create_sub_cert  = var.aws_r53_create_sub_cert
  aws_r53_cert_arn         = var.aws_r53_cert_arn
  # R53
  aws_r53_domain_name       = var.aws_r53_domain_name
  aws_r53_sub_domain_name   = var.aws_r53_sub_domain_name
  # Others
  aws_route53_sone_id       = module.aws_route53.zone_id
  common_tags               = local.default_tags
  fqdh_provided             = local.fqdn_provided
}

module "aws_route53" {
  source = "../../modules/aws/route53"
  count  = var.aws_r53_enable ? 1 : 0
  # R53 values
  aws_r53_domain_name        = var.aws_r53_domain_name
  aws_r53_sub_domain_name    = var.aws_r53_sub_domain_name
  aws_r53_root_domain_deploy = var.aws_r53_root_domain_deploy
  aws_r53_enable_cert        = var.aws_r53_enable_cert
  # ELB
  aws_elb_dns_name           = aws_elb.vm_lb.dns_name
  aws_elb_zone_id            = aws_elb.vm_lb.zone_id
  aws_elb_listen_port        = var.aws_elb_listen_port
  # Certs
  aws_certificates_selected_arn = var.aws_r53_enable_cert ? module.aws_certificates.selected_arn : ""
  # Others
  fqdh_provided              = local.fqdn_provided
  common_tags                = local.default_tags
}

locals {
  default_tags = merge(local.aws_tags, var.aws_additional_tags)
  fqdn_provided = (
    (var.aws_r53_domain_name != "") ?
    (var.aws_r53_sub_domain_name != "" ?
      true :
      var.aws_r53_root_domain_deploy ? true : false
    ) :
    false
  )
}