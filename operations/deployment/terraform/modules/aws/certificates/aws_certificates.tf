# Lookup for main domain.
data "aws_route53_zone" "selected" {
  count        = var.aws_r53_domain_name != "" ? 1 : 0
  name         = "${var.aws_r53_domain_name}."
  private_zone = false
}

data "aws_acm_certificate" "issued" {
  #count  = local.is_enabled_and_valid ? (!var.aws_r53_create_root_cert ? (!var.aws_r53_create_sub_cert ? (var.fqdn_provided ? 1 : 0) : 0) : 0) :0
  for_each = (!var.aws_r53_create_root_cert && !var.aws_r53_create_sub_cert && local.is_enabled_and_valid) ? {
    "domain"   = var.aws_r53_domain_name,
    "wildcard" = "*.${var.aws_r53_domain_name}",
    "sub"      = "${var.aws_r53_sub_domain_name}.${var.aws_r53_domain_name}"
  } : {}
  domain = each.value
  #domain = var.aws_r53_domain_name
}

# This block will create and validate the root domain and www cert
resource "aws_acm_certificate" "root_domain" {
  count                     = local.is_enabled_and_valid ? (var.aws_r53_create_root_cert ? (var.aws_r53_domain_name != "" ? 1 : 0) : 0) : 0
  domain_name               = var.aws_r53_domain_name
  subject_alternative_names = ["*.${var.aws_r53_domain_name}", "${var.aws_r53_domain_name}"]
  validation_method         = "DNS"
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "root_domain" {
  count           = local.is_enabled_and_valid ? (var.aws_r53_create_root_cert ? (var.aws_r53_domain_name != "" ? 1 : 0) : 0) : 0
  allow_overwrite = true
  name            = tolist(aws_acm_certificate.root_domain[0].domain_validation_options)[0].resource_record_name
  records         = [tolist(aws_acm_certificate.root_domain[0].domain_validation_options)[0].resource_record_value]
  type            = tolist(aws_acm_certificate.root_domain[0].domain_validation_options)[0].resource_record_type
  zone_id         = data.aws_route53_zone.selected[0].zone_id
  ttl             = 60
}

resource "aws_acm_certificate_validation" "root_domain" {
  count                   = local.is_enabled_and_valid ? (var.aws_r53_create_root_cert ? (var.aws_r53_domain_name != "" ? 1 : 0) : 0) : 0
  certificate_arn         = aws_acm_certificate.root_domain[0].arn
  validation_record_fqdns = [for record in aws_route53_record.root_domain : record.fqdn]
}


# This block will create and validate the sub domain cert ONLY
resource "aws_acm_certificate" "sub_domain" {
  count             = local.is_enabled_and_valid ? (var.aws_r53_create_sub_cert ? (var.aws_r53_domain_name != "" ? (var.aws_r53_sub_domain_name != "" ? (var.aws_r53_create_root_cert ? 0 : 1) : 0) : 0) : 0) : 0
  domain_name       = "${var.aws_r53_sub_domain_name}.${var.aws_r53_domain_name}"
  validation_method = "DNS"
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "sub_domain" {
  count           = local.is_enabled_and_valid ? (var.aws_r53_create_sub_cert ? (var.aws_r53_domain_name != "" ? (var.aws_r53_sub_domain_name != "" ? (var.aws_r53_create_root_cert ? 0 : 1) : 0) : 0) : 0) : 0
  allow_overwrite = true
  name            = tolist(aws_acm_certificate.sub_domain[0].domain_validation_options)[0].resource_record_name
  records         = [tolist(aws_acm_certificate.sub_domain[0].domain_validation_options)[0].resource_record_value]
  type            = tolist(aws_acm_certificate.sub_domain[0].domain_validation_options)[0].resource_record_type
  zone_id         = data.aws_route53_zone.selected[0].zone_id
  ttl             = 60
}

resource "aws_acm_certificate_validation" "sub_domain" {
  count                   = local.is_enabled_and_valid ? (var.aws_r53_create_sub_cert ? (var.aws_r53_domain_name != "" ? (var.aws_r53_create_root_cert ? 0 : 1) : 0) : 0) : 0
  certificate_arn         = aws_acm_certificate.sub_domain[0].arn
  validation_record_fqdns = [for record in aws_route53_record.sub_domain : record.fqdn]
}

locals {
  is_enabled_and_valid = var.aws_r53_domain_name != "" ? true : false
  selected_arn = (
    local.is_enabled_and_valid ?
    (var.aws_r53_cert_arn != "" ? var.aws_r53_cert_arn :
      (!var.aws_r53_create_root_cert ?
        (!var.aws_r53_create_sub_cert ?
          (var.fqdn_provided ? local.acm_arn : "")
          : aws_acm_certificate.sub_domain[0].arn
        ) : aws_acm_certificate.root_domain[0].arn
      )
    ) : ""
  )
  cert_available = (
    local.is_enabled_and_valid ?
    (var.aws_r53_cert_arn != "" ? true :
      (!var.aws_r53_create_root_cert ?
        (!var.aws_r53_create_sub_cert ?
          (var.fqdn_provided ? true : false)
          : true
        ) : true
      )
    ) : false
  )
  acm_arn = try(data.aws_acm_certificate.issued["domain"].arn, try(data.aws_acm_certificate.issued["wildcard"].arn, data.aws_acm_certificate.issued["sub"].arn, ""))
}

output "selected_arn" {
  value = local.selected_arn
}