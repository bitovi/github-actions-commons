#!/bin/bash

set -e

echo "In generate_provider.sh"

# Will print bitovi_provider.tf with the Terraform state file and path based on the first parameter. 
function generate_provider_aws () {
echo "
terraform {
  required_providers {
    aws = {
      source  = \"hashicorp/aws\"
      version = \"~> 5.0\"
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
    tags = local.common_tags
  }
}
" > "${GITHUB_ACTION_PATH}/operations/deployment/terraform/aws/$1/bitovi_provider.tf"
}

generate_provider_aws rds
generate_provider_aws efs
generate_provider_aws ec2
generate_provider_aws eks

echo "Done with generate_provider.sh"