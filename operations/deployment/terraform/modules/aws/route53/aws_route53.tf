data "aws_route53_zone" "selected" {
  count        = var.aws_r53_domain_name != "" ? 1 : 0
  name         = "${var.aws_r53_domain_name}."
  private_zone = false
}

resource "aws_route53_record" "dev" {
  count   = var.fqdn_provided ? (var.aws_r53_root_domain_deploy ? 0 : 1) : 0
  zone_id = data.aws_route53_zone.selected[0].zone_id
  name    = "${var.aws_r53_sub_domain_name}.${var.aws_r53_domain_name}"
  type    = "A"

  alias {
    name                   = aws_elb.vm_lb.dns_name
    zone_id                = aws_elb.vm_lb.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "root-a" {
  count   = var.fqdn_provided ? (var.aws_r53_root_domain_deploy ? 1 : 0) : 0
  zone_id = data.aws_route53_zone.selected[0].zone_id
  name    = var.aws_r53_domain_name
  type    = "A"

  alias {
    name                   = aws_elb.vm_lb.dns_name
    zone_id                = aws_elb.vm_lb.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "www-a" {
  count   = var.fqdn_provided ? (var.aws_r53_root_domain_deploy ? 1 : 0) : 0
  zone_id = data.aws_route53_zone.selected[0].zone_id
  name    = "www.${var.aws_r53_domain_name}"
  type    = "A"

  alias {
    name                   = aws_elb.vm_lb.dns_name
    zone_id                = aws_elb.vm_lb.zone_id
    evaluate_target_health = true
  }
}

locals {
  protocol    = var.aws_r53_enable_cert ? var.aws_certificates_selected_arn != "" ? "https://" : "http://" : "http://"
  public_port = var.aws_elb_listen_port != "" ? ":${var.aws_elb_listen_port}" : ""
  url = (var.fqdn_provided ?
    (var.aws_r53_root_domain_deploy ?
      "${local.protocol}${var.aws_r53_domain_name}${local.public_port}" :
      "${local.protocol}${var.aws_r53_sub_domain_name}.${var.aws_r53_domain_name}${local.public_port}"
    ) :
  "${local.protocol}${aws_elb.vm_lb.dns_name}${local.public_port}")
}

output "application_public_dns" {
  description = "Public DNS address for the application or load balancer public DNS"
  value       = local.url
}

output "vm_url" {
  value = local.url
}