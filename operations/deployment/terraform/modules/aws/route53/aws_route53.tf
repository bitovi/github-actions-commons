data "aws_route53_zone" "selected" {
  name         = "${var.aws_r53_domain_name}."
  private_zone = false
}

locals {
  aws_elb_zone_id = var.aws_elb_zone_id
}

#data "aws_route53_records" "dev" {
#  zone_id    = data.aws_route53_zone.selected.zone_id
#  name_regex = "${var.aws_r53_sub_domain_name}.${var.aws_r53_domain_name}"
#}
#
#resource "aws_route53_record" "dev" {
#  count   = var.fqdn_provided ? (var.aws_r53_root_domain_deploy ? 0 : 1) : 0
#  zone_id = data.aws_route53_zone.selected.zone_id
#  name    = "${var.aws_r53_sub_domain_name}.${var.aws_r53_domain_name}"
#  type    = "A"
#
#  alias {
#    name                   = var.aws_elb_dns_name
#    zone_id                = data.aws_route53_records.dev.resource_record_sets.alias_target[0].zone_id != var.aws_elb_zone_id ? var.aws_elb_zone_id : data.aws_route53_records.dev.resource_record_sets.alias_target[0].zone_id
#     #zone_id                = var.aws_elb_zone_id  # <-- This is different!
#    evaluate_target_health = true
#  }
#}

data "aws_route53_records" "existing_dev" {
  zone_id    = data.aws_route53_zone.selected.zone_id
  name_regex = "${var.aws_r53_sub_domain_name}.${var.aws_r53_domain_name}"
}

# Or if you really need to check existing records, make it safer:
locals {
  existing_zone_id = try(data.aws_route53_records.existing_dev.resource_record_sets[0].alias_target.zone_id) != "" ? data.aws_route53_records.existing_dev.resource_record_sets[0].alias_target.zone_id : var.aws_elb_zone_id
}

resource "aws_route53_record" "dev" {
  count   = var.fqdn_provided ? (var.aws_r53_root_domain_deploy ? 0 : 1) : 0
  zone_id = data.aws_route53_zone.selected.zone_id
  name    = "${var.aws_r53_sub_domain_name}.${var.aws_r53_domain_name}"
  type    = "A"

  alias {
    name                   = var.aws_elb_dns_name
    zone_id                = local.existing_zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "root-a" {
  count   = var.fqdn_provided ? (var.aws_r53_root_domain_deploy ? 1 : 0) : 0
  zone_id = data.aws_route53_zone.selected.zone_id
  name    = var.aws_r53_domain_name
  type    = "A"

  alias {
    name                   = var.aws_elb_dns_name
    zone_id                = var.aws_elb_zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "www-a" {
  count   = var.fqdn_provided ? (var.aws_r53_root_domain_deploy ? 1 : 0) : 0
  zone_id = data.aws_route53_zone.selected.zone_id
  name    = "www.${var.aws_r53_domain_name}"
  type    = "A"

  alias {
    name                   = var.aws_elb_dns_name
    zone_id                = var.aws_elb_zone_id
    evaluate_target_health = true
  }
}

locals {
  protocol = var.aws_r53_enable_cert ? var.aws_certificates_selected_arn != "" ? "https://" : "http://" : "http://"
  url      = (var.fqdn_provided ?
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