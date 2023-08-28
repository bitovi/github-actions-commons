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
    kubernetes = {
      source = \"hashicorp/kubernetes\"
      version = \">= 2.22\"
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
    tags = local.default_tags
  }
}

provider \"aws\" {
  region = \"${AWS_DEFAULT_REGION}\"
  alias  = \"ec2\"
  default_tags {
    tags = local.default_tags,
           jsondecode(var.aws_ec2_additional_tags)
  }
}

" > "${GITHUB_ACTION_PATH}/operations/deployment/terraform/$1/bitovi_provider.tf"
}

generate_provider_aws aws
generate_provider_aws eks

echo "Done with generate_provider.sh"