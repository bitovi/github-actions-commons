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

set -x

echo "In afterhook - generate-outputs.sh"
echo "ENV After Terra"
env

ls -lah ${BITOPS_ENVROOT}/env-files/
ls -lah ${BITOPS_ENVROOT}
ls -lah $GITHUB_ACTION_PATH/operations/
ls -lah $GITHUB_ACTION_PATH
ls -lah $BITOPS_ENVROOT/terraform/

if [ "$BITOPS_TERRAFORM_COMMAND" != "destroy" ]; then
  # The sed command will make each variable be in it's line, and in case a list is present, will transform it into a line
  terraform output | sed -e ':a;/["\)]$/!N;s/\n//;ta' -e 's/ *= */=/g;s/[" ]//g;s/,\([]]\)/\1/g' > ${BITOPS_ENVROOT}/env-files/bo-out.env
  # Generating ec2 terraform .env
  export BITOPS_EC2_PUBLIC_IP="$(cat ${BITOPS_ENVROOT}/env-files/bo-out.env| grep instance_public_ip | awk -F"=" '{print $2}')"
  export BITOPS_EC2_PUBLIC_URL="$(cat ${BITOPS_ENVROOT}/env-files/bo-out.env| grep instance_public_dns | awk -F"=" '{print $2}')"
  if [ -n "$BITOPS_EC2_PUBLIC_URL" ]; then
    echo -en "
#### EC2 values  deployments:
AWS_INSTANCE_URL="$BITOPS_EC2_PUBLIC_URL"

" > $BITOPS_ENVROOT/terraform/ec2.env
  fi
  if [ -n "$BITOPS_EC2_PUBLIC_IP" ]; then
      sed -i "s/BITOPS_EC2_PUBLIC_IP/$(echo $BITOPS_EC2_PUBLIC_IP)/" ${BITOPS_ENVROOT}/terraform/ec2/inventory.yaml
  fi
fi

echo "GAP -> $GITHUB_ACTION_PATH" 
ls -lah $GITHUB_ACTION_PATH
echo "end terraform output for bo-out"
cat ${BITOPS_ENVROOT}/env-files/bo-out.env