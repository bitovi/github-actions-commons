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

# Generate GH Incoming pieces


echo GH_CALLING_REPO
echo $GH_CALLING_REPO
echo GH_INPUT_ANSIBLE
echo $GH_INPUT_ANSIBLE
echo "GH_CALLING_REPO/GH_INPUT_ANSIBLE"
echo "$GH_CALLING_REPO/$GH_INPUT_ANSIBLE"
echo GH_INPUT_ANSIBLE_PLAYBOOK
echo $GH_INPUT_ANSIBLE_PLAYBOOK
GH_CALLING_REPO=$(echo $GH_CALLING_REPO | awk -F "/" '{OFS="/"; NF=7; print}')
echo "New GH Calling Repo ----> $GH_CALLING_REPO"

if [ -n "$GH_CALLING_REPO" ]; then
  #  ANSIBLE PART
  echo "Inside ansible part"
  if [ -n "$GH_INPUT_ANSIBLE" ]; then
    GH_INPUT_ANSIBLE_PATH="$GH_CALLING_REPO/$GH_INPUT_ANSIBLE"
    echo "GH_INPUT_ANSIBLE_PATH -> $GH_INPUT_ANSIBLE_PATH"
    if [ -s "$GH_INPUT_ANSIBLE_PATH/$GH_INPUT_ANSIBLE_PLAYBOOK" ]; then
      echo " --> Moving $GH_INPUT_ANSIBLE_PATH"
      ls -lah "$GH_INPUT_ANSIBLE_PATH"
      mv "$GH_INPUT_ANSIBLE_PATH" "$GITHUB_ACTION_PATH/operations/deployment/ansible/."
  
      if ! [ -s "$GH_INPUT_ANSIBLE_PATH/bitops.config.yaml" ]; then

echo -en "
ansible:
  cli:
    main-playbook: $GH_INPUT_ANSIBLE_PLAYBOOK
  options: {}
" >  $GITHUB_ACTION_PATH/operations/deployment/ansible/$GH_INPUT_ANSIBLE/bitops.config.yaml
echo "Cating bitops.config.yaml"
cat $GITHUB_ACTION_PATH/operations/deployment/ansible/$GH_INPUT_ANSIBLE/bitops.config.yaml
      fi

      # Add Ansible - Incoming GH
echo -en "
    ansible/$GH_INPUT_ANSIBLE:
      plugin: ansible
" >> $GITHUB_ACTION_PATH/operations/deployment/bitops.config.yaml
echo "Cating MAIN bitops.config.yaml"
$GITHUB_ACTION_PATH/operations/deployment/bitops.config.yaml
    fi
  fi
  
  # TERRAFORM PART
  # TBC
fi