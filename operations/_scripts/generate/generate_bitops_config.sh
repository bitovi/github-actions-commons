#!/bin/bash

set -e

echo "In generate_bitops_config.sh"

function alpha_only() {
    echo "$1" | tr -cd '[:alpha:]' | tr '[:upper:]' '[:lower:]'
}

CONFIG_STACK_ACTION="apply"
if [ "$TF_STACK_DESTROY" == "true" ]; then
  CONFIG_STACK_ACTION="destroy"
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

# Terraform Bitops Config
echo -en "
terraform:
  cli:
    stack-action: $CONFIG_STACK_ACTION
    $targets_attribute
  options: {}
" > $GITHUB_ACTION_PATH/operations/deployment/terraform/bitops.config.yaml


# Global Bitops Config
echo -en "
bitops:
  deployments:
    generators:
      plugin: terraform
    terraform:
      plugin: terraform
" > $GITHUB_ACTION_PATH/operations/deployment/bitops.config.yaml

# Ansible - Fetch repo - Do we need an if here?
#if [[ $(alpha_only "$AWS_EFS_CREATE") == true ]] || [[ $(alpha_only "$AWS_EFS_CREATE_HA") == true ]] ; then
echo -en "
    ansible/clone_repo:
      plugin: ansible
" >> $GITHUB_ACTION_PATH/operations/deployment/bitops.config.yaml
#fi

# Ansible - Install EFS
if [[ $(alpha_only "$AWS_EFS_CREATE") == true ]] || [[ $(alpha_only "$AWS_EFS_CREATE_HA") == true ]] ; then
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

if [[ $(alpha_only "$ST2_INSTALL") == true ]]; then
echo -en "
    st2:
      plugin: ansible
" >> $GITHUB_ACTION_PATH/operations/deployment/bitops.config.yaml
fi