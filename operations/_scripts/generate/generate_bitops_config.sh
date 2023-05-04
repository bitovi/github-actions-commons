#!/bin/bash

set -e

echo "In generate_bitops_config.sh"

function alpha_only() {
  echo "$1" | tr -cd '[:alpha:]' | tr '[:upper:]' '[:lower:]'
}

function create_bitops_terraform_config() {
  if [[ $(alpha_only "$2") == true ]] && [[ $(alpha_only "TF_STACK_DESTROY") != "true" ]]; then
    action="apply"
  else
    action="destroy"
  fi

  echo -en "
terraform:
  cli:
    stack-action: "$action"
    $targets_attribute
  options: {}
" > $GITHUB_ACTION_PATH/operations/deployment/terraform/$1/bitops.config.yaml
}

if [[ "$(alpha_only $TF_STACK_DESTROY)" == "true" ]]; then
  ANSIBLE_SKIP=true
fi

targets_attribute="targets:"
if [ -n "$TF_TARGETS" ]; then
  # Iterate over the provided comma-delimited string
  for item in $(echo $TF_TARGETS | sed "s/,/ /g"); do
    # Add the item to the YAML list
  targets="$targets 
      - $item"
  done
fi
# random_integer.az_select needs to be created before the "full stack" to avoid a potential state dependency locks
targets="$targets
    - random_integer.az_select"
targets_attribute="$targets_attribute $targets"

# Check EFS 
if [[ $(alpha_only "$AWS_EFS_CREATE") == true ]] || [[ $(alpha_only "$AWS_EFS_CREATE_HA") == true ]] || [ -n "$AWS_EFS_MOUNT_ID" ]; then 
  AWS_EFS_ENABLE="true"
else
  AWS_EFS_ENABLE="false"
fi

#Will create bitops.config.yaml for that terraform folder
create_bitops_terraform_config rds $AWS_POSTGRES_ENABLE
create_bitops_terraform_config efs $AWS_EFS_ENABLE
create_bitops_terraform_config ec2 $AWS_EC2_INSTANCE_CREATE

# Global Bitops Config
echo -en "
bitops:
  deployments:
    generators:
      plugin: terraform
" > $GITHUB_ACTION_PATH/operations/deployment/bitops.config.yaml

if [[ "$(alpha_only $BITOPS_CODE_ONLY)" != "true" ]]; then
  # Terraform - Generate infra
    echo -en "
    terraform/rds:
      plugin: terraform
    terraform/efs:
      plugin: terraform
    terraform/ec2:
      plugin: terraform
" >> $GITHUB_ACTION_PATH/operations/deployment/bitops.config.yaml

  if [[ "$(alpha_only $ANSIBLE_SKIP)" != "true" ]] && [[ "$(alpha_only $AWS_EC2_INSTANCE_CREATE)" == "true" ]] && [[ "$(alpha_only $AWS_EC2_INSTANCE_PUBLIC_IP)" == "true" ]]; then
    # Ansible - Fetch repo
    echo -en "
    ansible/clone_repo:
      plugin: ansible
" >> $GITHUB_ACTION_PATH/operations/deployment/bitops.config.yaml
    
    # Ansible - Install EFS
    if [[ $(alpha_only "$AWS_EFS_CREATE") == true ]] || [[ $(alpha_only "$AWS_EFS_CREATE_HA") == true ]] || [[ "$AWS_EFS_MOUNT_ID" != "" ]]; then
    echo -en "
    ansible/efs:
      plugin: ansible
" >> $GITHUB_ACTION_PATH/operations/deployment/bitops.config.yaml
    fi
    
    # Ansible - Install Docker
    if [[ $(alpha_only "$DOCKER_INSTALL") == true ]]; then
    echo -en "
    ansible/docker:
      plugin: ansible
" >> $GITHUB_ACTION_PATH/operations/deployment/bitops.config.yaml
    fi
  fi
fi

cat $GITHUB_ACTION_PATH/operations/deployment/bitops.config.yaml

echo "Done with generate_bitops_config.sh"