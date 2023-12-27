#!/bin/bash

set -e

echo "In generate_provider.sh"

function generate_tf_state_file_name () {
  if [ -n "$TF_STATE_FILE_NAME" ]; then
    filename="$TF_STATE_FILE_NAME"
  else
    filename="tf-state-$1"
  fi

  if [ -n "$TF_STATE_FILE_NAME_APPEND" ]; then
    filename="${filename}-${TF_STATE_FILE_NAME_APPEND}"
  fi
  echo $filename
}

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
    key     = \"$(generate_tf_state_file_name $1)\"
    encrypt = true #AES-256encryption
  }
}

provider \"aws\" {
  region = \"${AWS_DEFAULT_REGION}\"
  default_tags {
    tags = local.default_tags
  }
}" > "${GITHUB_ACTION_PATH}/operations/deployment/terraform/$1/bitovi_provider.tf"

  # Loop through the comma-separated list in $2
  IFS=',' read -ra modules <<< "$2"
  for module in "${modules[@]}"; do

echo "
provider \"aws\" {
  alias  = \"$module\"
  region = \"${AWS_DEFAULT_REGION}\"
  default_tags {
    tags = local.${module}_tags
  }
}" >> "${GITHUB_ACTION_PATH}/operations/deployment/terraform/$1/bitovi_provider.tf"
done

#echo "
#provider \"kubernetes\" {
#  alias                  = \"eks\"
#  host                   = data.aws_eks_cluster.eks_cluster.endpoint
#  cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks_cluster.certificate_authority.0.data)
#  token                  = data.aws_eks_cluster_auth.cluster_auth.token
#}" >> "${GITHUB_ACTION_PATH}/operations/deployment/terraform/$1/bitovi_provider.tf"
#}

generate_provider_aws aws ec2,r53,elb,efs,vpc,rds,aurora,ecs,db_proxy,redis,eks # Added eks here
#generate_provider_aws ecr ecr
#generate_provider_aws eks

echo "Done with generate_provider.sh"