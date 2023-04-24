#!/bin/bash

set -e

echo "In generate_bitops_config_code_only.sh"

function alpha_only() {
  echo "$1" | tr -cd '[:alpha:]' | tr '[:upper:]' '[:lower:]'
}

CONFIG_STACK_ACTION="apply"
if [ "$TF_STACK_DESTROY" == "true" ]; then
  CONFIG_STACK_ACTION="destroy"
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
    terraform:
      plugin: terraform
" >> $GITHUB_ACTION_PATH/operations/deployment/bitops.config.yaml

if [[ "$(alpha_only $ANSIBLE_SKIP)" != "true" ]]; then
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

if [ -n "$GH_ACTION_REPO" ]; then
  if [ -n "$GH_ACTION_INPUT_ANSIBLE" ] && [[ "$(alpha_only $ANSIBLE_SKIP)" != "true" ]]; then
    if [ -s "$GH_ACTION_INPUT_ANSIBLE_PATH/$GH_ACTION_INPUT_ANSIBLE_PLAYBOOK" ]; then
      # Add Ansible - Incoming GH to main bitops.config.yaml
      if [[ "$(alpha_only $BITOPS_CODE_ONLY)" == "true" ]]; then
        /tmp/yq ".bitops.deployments.ansible/incoming.plugin = \"ansible\"" -i $GITHUB_ACTION_PATH/operations/deployment/bitops.config.yaml
      fi
    else
      echo "::error::Couldn't find $GH_ACTION_INPUT_ANSIBLE_PLAYBOOK inside incoming Ansible folder."
    fi
  fi
  
  # TERRAFORM PART
  # TBC
fi




echo "Done with generate_bitops_config.sh"