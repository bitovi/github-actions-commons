#!/bin/bash

set -e

echo "In generate_provider.sh"

# Will print bitovi_provider.tf with the Terraform state file and path based on the first parameter. 
function generate_provider () {
echo "
terraform {
  required_providers {
    aws = {
      source  = \"hashicorp/aws\"
      version = \"~> 4.30\"
    }
    random = {
      source  = \"hashicorp/random\"
      version = \">= 2.2\"
    }
  }

  backend \"s3\" {
    region  = \"${AWS_DEFAULT_REGION}\"
    bucket  = \"${TF_STATE_BUCKET}\"
    key     = \"tf-state-$1\"
    encrypt = true #AES-256encryption
  }
}

provider \"aws\" {
  region = \"${AWS_DEFAULT_REGION}\"
  default_tags {
    tags = merge(
      local.aws_tags,
      var.aws_additional_tags
    )
  }
}
" > "${GITHUB_ACTION_PATH}/operations/deployment/terraform/$1/bitovi_provider.tf"
}

generate_provider rds
generate_provider efs
generate_provider ec2

echo "Done with generate_provider.sh"