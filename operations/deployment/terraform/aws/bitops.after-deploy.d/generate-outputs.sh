#!/bin/bash

# """
# What
#   This bash script uses Terraform to output the values of environment 
#   variables and store them in a file called bo-out.env. 
#   The script checks if Terraform is being used to destroy the environment, and if not, 
#   it runs Terraform output and removes the quotation marks from the output before storing 
#   it in the bo-out.env file.
# Why
#   The bo-out.env file is used by Ansible to populate variables passed on by Terraform
# """

echo "In afterhook - generate-outputs.sh"
TARGET_FILE="/opt/bitops_deployment/bo-out.env"

if [ "$BITOPS_TERRAFORM_COMMAND" != "destroy" ]; then
  # The sed command will make each variable be in it's line, and in case a list is present, will transform it into a line
  terraform output | sed -e ':a;/["\)]$/!N;s/\n//;ta' -e 's/ *= */=/g;s/[" ]//g;s/,\([]]\)/\1/g' > $TARGET_FILE
  # Generating ec2 terraform .env
  export BITOPS_EC2_PRIVATE_IP="$(cat $TARGET_FILE | grep instance_private_ip | awk -F"=" '{print $2}')"
  export BITOPS_EC2_PRIVATE_URL="$(cat $TARGET_FILE | grep instance_private_dns | awk -F"=" '{print $2}')"
  export BITOPS_EC2_PUBLIC_IP="$(cat $TARGET_FILE | grep instance_public_ip | awk -F"=" '{print $2}')"
  export BITOPS_EC2_PUBLIC_URL="$(cat $TARGET_FILE | grep instance_public_dns | awk -F"=" '{print $2}')"
  export BITOPS_EC2_INSTANCE_ENDPOINT="$(cat $TARGET_FILE | grep instance_endpoint | awk -F"=" '{print $2}')"
  export BITOPS_EC2_ELB_DNS="$(cat $TARGET_FILE | grep aws_elb_dns_name | awk -F"=" '{print $2}')"
  export BITOPS_EC2_PUBLIC_DNS="$(cat $TARGET_FILE | grep application_public_dns | awk -F"=" '{print $2}')"
  export BITOPS_EC2_VM_URL="$(cat $TARGET_FILE | grep vm_url | awk -F"=" '{print $2}')"
  if [ -n "$BITOPS_EC2_VM_URL" ]; then
    export BITOPS_EC2_URL="$BITOPS_EC2_VM_URL"
  else
    export BITOPS_EC2_URL="$BITOPS_EC2_INSTANCE_ENDPOINT"
  fi
  
  # ECR
  export BITOPS_ECR_REPO_ARN="$(cat $TARGET_FILE | grep ecr_repository_arn | awk -F"=" '{print $2}')"
  export BITOPS_ECR_REPO_ID="$(cat $TARGET_FILE | grep ecr_repository_registry_id | awk -F"=" '{print $2}')"
  export BITOPS_ECR_REPO_URL="$(cat $TARGET_FILE | grep ecr_repository_url | awk -F"=" '{print $2}')"
  
  if [ -n "$BITOPS_EC2_URL" ]; then
    echo -en "
#### EC2 values  deployments:
AWS_INSTANCE_PRIVATE_IP="$BITOPS_EC2_PRIVATE_IP"
AWS_INSTANCE_PRIVATE_URL="$BITOPS_EC2_PRIVATE_DNS"
AWS_INSTANCE_IP="$BITOPS_EC2_PUBLIC_IP"
AWS_INSTANCE_URL="$BITOPS_EC2_PUBLIC_URL"
AWS_INSTANCE_ENDPOINT="$BITOPS_EC2_INSTANCE_ENDPOINT"
AWS_INSTANCE_ELB="$BITOPS_EC2_ELB_DNS"
AWS_INSTANCE_DNS="$BITOPS_EC2_PUBLIC_DNS"
AWS_INSTANCE_VM_URL="$BITOPS_EC2_VM_URL"
AWS_INSTANCE_URL="$BITOPS_EC2_URL"
" > $BITOPS_ENVROOT/terraform/aws/ec2.env
  fi

  if [ -n "$BITOPS_ECR_REPO_ARN" ]; then
    echo -en "
#### ECR values:
ECR_REPO_ARN="$BITOPS_ECR_REPO_ARN"
ECR_REPO_ID="$BITOPS_ECR_REPO_ID"
ECR_REPO_URL="$BITOPS_ECR_REPO_URL"
" > $BITOPS_ENVROOT/terraform/aws/ecr.env
  fi
fi

echo "end terraform output for bo-out"