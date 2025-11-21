data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}

locals {
    aws_ecr_repo_read_arn = var.aws_ecr_repo_read_arn != "" ? [for n in split(",", var.aws_ecr_repo_read_arn) : (n)] : []
    aws_ecr_repo_write_arn = var.aws_ecr_repo_write_arn != "" ? [for n in split(",", var.aws_ecr_repo_write_arn) : (n)] : []
    aws_ecr_repo_read_arn_lambda = var.aws_ecr_repo_read_arn_lambda != "" ? [for n in split(",", var.aws_ecr_repo_read_arn_lambda) : (n)] : []
    aws_ecr_repo_read_external_aws_account = var.aws_ecr_repo_read_external_aws_account != "" ? [for n in split(",", var.aws_ecr_repo_read_external_aws_account) : "arn:${data.aws_partition.current.partition}:iam::${n}:root"] : []
    aws_ecr_repo_write_external_aws_account = var.aws_ecr_repo_write_external_aws_account != "" ? [for n in split(",", var.aws_ecr_repo_write_external_aws_account) : "arn:${data.aws_partition.current.partition}:iam::${n}:root"] : []
}

# Policy used by both private and public repositories
data "aws_iam_policy_document" "repository" {
  count = var.aws_ecr_repo_policy_create ? 1 : 0

  dynamic "statement" {
    for_each = var.aws_ecr_repo_type == "public" ? [1] : []

    content {
      sid = "PublicReadOnly"

      principals {
        type = "AWS"
        identifiers = coalescelist(
          local.aws_ecr_repo_read_arn,
          ["*"],
        )
      }

      actions = [
        "ecr-public:BatchGetImage",
        "ecr-public:GetDownloadUrlForLayer",
      ]
    }
  }

  dynamic "statement" {
    for_each = var.aws_ecr_repo_type == "private" ? [1] : []

    content {
      sid = "PrivateReadOnly"

      principals {
        type = "AWS"
        identifiers = coalescelist(
          concat(local.aws_ecr_repo_read_arn, local.aws_ecr_repo_write_arn),
          ["arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:root"],
        )
      }

      actions = [
        "ecr:GetAuthorizationToken",
        "ecr:BatchCheckLayerAvailability",
        "ecr:BatchGetImage",
        "ecr:DescribeImageScanFindings",
        "ecr:DescribeImages",
        "ecr:DescribeRepositories",
        "ecr:GetDownloadUrlForLayer",
        "ecr:GetLifecyclePolicy",
        "ecr:GetLifecyclePolicyPreview",
        "ecr:GetRepositoryPolicy",
        "ecr:ListImages",
        "ecr:ListTagsForResource",
      ]
    }
  }

  dynamic "statement" {
    for_each = var.aws_ecr_repo_type == "private" && length(local.aws_ecr_repo_read_arn_lambda) > 0 ? [1] : []

    content {
      sid = "PrivateLambdaReadOnly"

      principals {
        type        = "Service"
        identifiers = ["lambda.amazonaws.com"]
      }

      actions = [
        "ecr:BatchGetImage",
        "ecr:GetDownloadUrlForLayer",
      ]

      condition {
        test     = "StringLike"
        variable = "aws:sourceArn"

        values = local.aws_ecr_repo_read_arn_lambda
      }

    }
  }

  dynamic "statement" {
    for_each = length(local.aws_ecr_repo_write_arn) > 0 && var.aws_ecr_repo_type == "private" ? [local.aws_ecr_repo_write_arn] : []

    content {
      sid = "ReadWrite"

      principals {
        type        = "AWS"
        identifiers = statement.value
      }

      actions = [
        "ecr:PutImage",
        "ecr:InitiateLayerUpload",
        "ecr:UploadLayerPart",
        "ecr:CompleteLayerUpload",
      ]
    }
  }

  dynamic "statement" {
    for_each = length(local.aws_ecr_repo_write_arn) > 0 && var.aws_ecr_repo_type == "public" ? [local.aws_ecr_repo_write_arn] : []

    content {
      sid = "ReadWrite"

      principals {
        type        = "AWS"
        identifiers = statement.value
      }

      actions = [
        "ecr-public:BatchCheckLayerAvailability",
        "ecr-public:CompleteLayerUpload",
        "ecr-public:InitiateLayerUpload",
        "ecr-public:PutImage",
        "ecr-public:UploadLayerPart",
      ]
    }
  }

  dynamic "statement" {
    for_each = length(local.aws_ecr_repo_write_arn) > 0 && var.aws_ecr_repo_type == "public" ? [local.aws_ecr_repo_write_arn] : []

    content {
      sid = "ReadWrite"

      principals {
        type        = "AWS"
        identifiers = statement.value
      }

      actions = [
        "ecr-public:BatchCheckLayerAvload",
        "ecr-public:CompleteLayerUpload",
        "ecr-public:InitiateLayerUpload",
        "ecr-public:PutImage",
        "ecr-public:UploadLayerPart",
      ]
    }
  }

  dynamic "statement" {
    for_each = length(local.aws_ecr_repo_read_external_aws_account) > 0 && var.aws_ecr_repo_type == "private" ? [local.aws_ecr_repo_read_external_aws_account] : []

    content {
      sid = "ExternalAccountReadOnly"

      principals {
        type        = "AWS"
        identifiers = statement.value
      }

      actions = [
        "ecr:GetAuthorizationToken",
        "ecr:BatchCheckLayerAvailability",
        "ecr:BatchGetImage",
        "ecr:DescribeImageScanFindings",
        "ecr:DescribeImages",
        "ecr:DescribeRepositories",
        "ecr:GetDownloadUrlForLayer",
        "ecr:GetLifecyclePolicy",
        "ecr:GetLifecyclePolicyPreview",
        "ecr:GetRepositoryPolicy",
        "ecr:ListImages",
        "ecr:ListTagsForResource",
      ]
    }
  }

  dynamic "statement" {
    for_each = length(local.aws_ecr_repo_write_external_aws_account) > 0 && var.aws_ecr_repo_type == "private" ? [local.aws_ecr_repo_write_external_aws_account] : []

    content {
      sid = "ExternalAccountReadWrite"

      principals {
        type        = "AWS"
        identifiers = statement.value
      }

      actions = [
        "ecr:GetAuthorizationToken",
        "ecr:BatchCheckLayerAvailability",
        "ecr:BatchGetImage",
        "ecr:DescribeImageScanFindings",
        "ecr:DescribeImages",
        "ecr:DescribeRepositories",
        "ecr:GetDownloadUrlForLayer",
        "ecr:GetLifecyclePolicy",
        "ecr:GetLifecyclePolicyPreview",
        "ecr:GetRepositoryPolicy",
        "ecr:ListImages",
        "ecr:ListTagsForResource",
        "ecr:PutImage",
        "ecr:InitiateLayerUpload",
        "ecr:UploadLayerPart",
        "ecr:CompleteLayerUpload",
      ]
    }
  }
}