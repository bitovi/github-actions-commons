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
    key     = \"tf-state\"
    encrypt = true #AES-256encryption
  }
}

provider \"aws\" {
  region = \"${AWS_DEFAULT_REGION}\"
  default_tags {
    tags = local.default_tags
  }
}

provider \"kubernetes\" {
  alias                  = \"eks\"
  host                   = module.eks.aws_eks_cluster_endpoint
  cluster_ca_certificate = module.eks.aws_eks_cluster_ca_certificate
  token                  = module.eks.aws_eks_cluster_auth_token
}
" > "${GITHUB_ACTION_PATH}/operations/deployment/terraform/aws/bitovi_provider.tf"
}

generate_provider_aws

cat "${GITHUB_ACTION_PATH}/operations/deployment/terraform/aws/bitovi_provider.tf"

echo "Done with generate_provider.sh"