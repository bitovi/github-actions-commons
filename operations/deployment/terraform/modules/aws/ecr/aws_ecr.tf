################################################################################
# Repository
################################################################################

resource "aws_ecr_repository" "this" {
  count = var.aws_ecr_repo_type == "private" ? 1 : 0

  name                 = var.aws_ecr_repo_name != "" ? var.aws_ecr_repo_name : "${var.aws_resource_identifier}-ecr"
  image_tag_mutability = var.aws_ecr_repo_mutable ? "MUTABLE" : "IMMUTABLE"

  encryption_configuration {
    encryption_type = var.aws_ecr_repo_encryption_type
    kms_key         = var.aws_ecr_repo_encryption_key_arn
  }

  force_delete = var.aws_ecr_repo_force_destroy

  image_scanning_configuration {
    scan_on_push = var.aws_ecr_repo_image_scan
  }
}

################################################################################
# Repository Policy
################################################################################

resource "aws_ecr_repository_policy" "this" {
  count = var.aws_ecr_repo_type == "private" && var.aws_ecr_repo_policy_attach ? 1 : 0

  repository = aws_ecr_repository.this[0].name
  policy     = var.aws_ecr_repo_policy_input != "" ? var.aws_ecr_repo_policy_input : data.aws_iam_policy_document.repository[0].json
}

################################################################################
# Lifecycle Policy
################################################################################

resource "aws_ecr_lifecycle_policy" "this" {
  count = var.aws_ecr_repo_type == "private" && var.aws_ecr_lifecycle_policy_input != "" ? 1 : 0

  repository = aws_ecr_repository.this[0].name
  policy     = var.aws_ecr_lifecycle_policy_input
}

################################################################################
# Public Repository
################################################################################

resource "aws_ecrpublic_repository" "this" {
  count = var.aws_ecr_repo_type == "public" ? 1 : 0

  repository_name = var.aws_ecr_repo_name != "" ? var.aws_ecr_repo_name : "${var.aws_resource_identifier}-ecr"

  dynamic "catalog_data" {
    for_each = length(var.aws_ecr_public_repo_catalog) > 0 ? [var.aws_ecr_public_repo_catalog] : []

    content {
      about_text        = try(catalog_data.value.about_text, null)
      architectures     = try(catalog_data.value.architectures, null)
      description       = try(catalog_data.value.description, null)
      logo_image_blob   = try(catalog_data.value.logo_image_blob, null)
      operating_systems = try(catalog_data.value.operating_systems, null)
      usage_text        = try(catalog_data.value.usage_text, null)
    }
  }
}

################################################################################
# Public Repository Policy
################################################################################

resource "aws_ecrpublic_repository_policy" "example" {
  count = var.aws_ecr_repo_type == "public" ? 1 : 0

  repository_name = aws_ecrpublic_repository.this[0].repository_name
  policy          = var.aws_ecr_repo_policy_input != "" ? var.aws_ecr_repo_policy_input : data.aws_iam_policy_document.repository[0].json
}

################################################################################
# Registry Policy
################################################################################

resource "aws_ecr_registry_policy" "this" {
  count = var.aws_ecr_registry_policy_input != "" ? 1 : 0

  policy = var.aws_ecr_registry_policy_input
}

################################################################################
# Registry Pull Through Cache Rule
################################################################################

resource "aws_ecr_pull_through_cache_rule" "this" {
  for_each = { for k, v in var.aws_ecr_registry_pull_through_cache_rules : k => v }

  ecr_repository_prefix = each.value.ecr_repository_prefix
  upstream_registry_url = each.value.upstream_registry_url
}

################################################################################
# Registry Scanning Configuration
################################################################################

resource "aws_ecr_registry_scanning_configuration" "this" {
  count = var.aws_ecr_registry_scan_config != "" ? 1 : 0

  scan_type = var.aws_ecr_registry_scan_config

  dynamic "rule" {
    for_each = var.aws_ecr_registry_scan_rule

    content {
      scan_frequency = rule.value.scan_frequency

      repository_filter {
        filter      = rule.value.filter
        filter_type = try(rule.value.filter_type, "WILDCARD")
      }
    }
  }
}

################################################################################
# Registry Replication Configuration
################################################################################

resource "aws_ecr_replication_configuration" "this" {
  count = length(var.aws_ecr_registry_replication_rules_input) > 0 ? 1 : 0

  replication_configuration {

    dynamic "rule" {
      for_each = var.aws_ecr_registry_replication_rules_input

      content {
        dynamic "destination" {
          for_each = rule.value.destinations

          content {
            region      = destination.value.region
            registry_id = destination.value.registry_id
          }
        }

        dynamic "repository_filter" {
          for_each = try(rule.value.repository_filters, [])

          content {
            filter      = repository_filter.value.filter
            filter_type = repository_filter.value.filter_type
          }
        }
      }
    }
  }
}

################################################################################
# Repository (Public and Private)
################################################################################

output "repository_arn" {
  description = "Full ARN of the repository"
  value       = try(aws_ecr_repository.this[0].arn, aws_ecrpublic_repository.this[0].arn, null)
}

output "repository_registry_id" {
  description = "The registry ID where the repository was created"
  value       = try(aws_ecr_repository.this[0].registry_id, aws_ecrpublic_repository.this[0].registry_id, null)
}

output "repository_url" {
  description = "The URL of the repository"
  value       = try(aws_ecr_repository.this[0].repository_url, aws_ecrpublic_repository.this[0].repository_uri, null)
}