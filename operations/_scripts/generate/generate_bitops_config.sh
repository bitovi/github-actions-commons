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


ls -lah $GH_CALLING_REPO
echo "Actions folder:"
ls -al /home/runner/work/_actions


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


### Generate incoming repo's
# Get yq to parse any incoming yaml
wget -q https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -O /tmp/yq && chmod +x /tmp/yq

if [ -n "$GH_CALLING_REPO" ]; then
  #  ANSIBLE PART
  echo "Inside ansible part"
  if [ -n "$GH_INPUT_ANSIBLE" ] && [[ "$(alpha_only $ANSIBLE_SKIP)" != "true" ]]; then
    GH_INPUT_ANSIBLE_PATH="$GH_CALLING_REPO/$GH_INPUT_ANSIBLE"
    echo "GH_INPUT_ANSIBLE_PATH -> $GH_INPUT_ANSIBLE_PATH"

    if [ -s "$GH_INPUT_ANSIBLE_PATH/$GH_INPUT_ANSIBLE_PLAYBOOK" ]; then
      if ! [ -s "$GH_INPUT_ANSIBLE_PATH/bitops.config.yaml" ]; then
        touch "$GH_INPUT_ANSIBLE_PATH/bitops.config.yaml"
        /tmp/yq ".ansible.cli.main-playbook = \"$GH_INPUT_ANSIBLE_PLAYBOOK\"" -i "$GH_INPUT_ANSIBLE_PATH/bitops.config.yaml"
      fi
      if [ -s "$GITHUB_WORKSPACE/$GH_INPUT_ANSIBLE_EXTRA_VARS_FILE" ] && [ -n "$GH_INPUT_ANSIBLE_EXTRA_VARS_FILE" ]; then
        /tmp/yq ".ansible.cli.extra-vars = \"@$(basename $GH_INPUT_ANSIBLE_EXTRA_VARS_FILE)\"" -i "$GH_INPUT_ANSIBLE_PATH/bitops.config.yaml"
        # Incoming Ansible folder from proxy action
        mv "$GH_INPUT_ANSIBLE_PATH" "$GITHUB_ACTION_PATH/operations/deployment/ansible/incoming"
        # Incoming Ansible vars-file from end-user action
        mv "$GITHUB_WORKSPACE/$GH_INPUT_ANSIBLE_EXTRA_VARS_FILE" "${GITHUB_ACTION_PATH}/operations/deployment/ansible/incoming/."
      else
        mv "$GH_INPUT_ANSIBLE_PATH" "$GITHUB_ACTION_PATH/operations/deployment/ansible/incoming"
      fi      
      # Add Ansible - Incoming GH to main bitops.config.yaml
echo -en "
    ansible/incoming:
      plugin: ansible
" >> $GITHUB_ACTION_PATH/operations/deployment/bitops.config.yaml
    else
      echo "::error::Couldn't find $GH_INPUT_ANSIBLE_PLAYBOOK inside incoming Ansible folder."
    fi
  fi
  
  # TERRAFORM PART
  # TBC
fi