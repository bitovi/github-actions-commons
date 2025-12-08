data "aws_route53_zone" "selected" {
  name         = "${var.aws_r53_domain_name}."
  private_zone = false
}

resource "aws_route53_record" "dev" {
  count   = var.fqdn_provided ? (var.aws_r53_root_domain_deploy ? 0 : 1) : 0
  zone_id = data.aws_route53_zone.selected.zone_id
  name    = "${var.aws_r53_sub_domain_name}.${var.aws_r53_domain_name}"
  type    = "A"

  dynamic "alias" {
    for_each = var.aws_elb_zone_id != "" ? [1] : []
    content {
      name                   = var.aws_elb_dns_name
      zone_id                = var.aws_elb_zone_id
      evaluate_target_health = true
    }
  }
  records = var.aws_elb_zone_id == "" ? [var.aws_elb_dns_name] : null
  ttl     = var.aws_elb_zone_id == "" ? 300 : null
}

resource "aws_route53_record" "root-a" {
  count   = var.fqdn_provided ? (var.aws_r53_root_domain_deploy ? 1 : 0) : 0
  zone_id = data.aws_route53_zone.selected.zone_id
  name    = var.aws_r53_domain_name
  type    = "A"

  dynamic "alias" {
    for_each = var.aws_elb_zone_id != "" ? [1] : []
    content {
      name                   = var.aws_elb_dns_name
      zone_id                = var.aws_elb_zone_id
      evaluate_target_health = true
    }
  }
  records = var.aws_elb_zone_id == "" ? [var.aws_elb_dns_name] : null
  ttl     = var.aws_elb_zone_id == "" ? 300 : null
}

resource "aws_route53_record" "www-a" {
  count   = var.fqdn_provided ? (var.aws_r53_root_domain_deploy ? 1 : 0) : 0
  zone_id = data.aws_route53_zone.selected.zone_id
  name    = "www.${var.aws_r53_domain_name}"
  type    = "A"

  dynamic "alias" {
    for_each = var.aws_elb_zone_id != "" ? [1] : []
    content {
      name                   = var.aws_elb_dns_name
      zone_id                = var.aws_elb_zone_id
      evaluate_target_health = true
    }
  }
  records = var.aws_elb_zone_id == "" ? [var.aws_elb_dns_name] : null
  ttl     = var.aws_elb_zone_id == "" ? 300 : null
}

locals {
  protocol = var.aws_r53_enable_cert ? var.aws_certificates_selected_arn != "" ? "https://" : "http://" : "http://"
  url = (var.fqdn_provided ?
    (var.aws_r53_root_domain_deploy ?
      "${local.protocol}${var.aws_r53_domain_name}" :
      "${local.protocol}${var.aws_r53_sub_domain_name}.${var.aws_r53_domain_name}"
    ) :
  "${local.protocol}${var.aws_elb_dns_name}")
}

output "vm_url" {
  value = local.url
}

output "zone_id" {
  value = data.aws_route53_zone.selected.zone_id
}