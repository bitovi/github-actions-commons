#!/bin/bash

set -e

echo "In generate_bitops_incoming.sh"

function alpha_only() {
  echo "$1" | tr -cd '[:alpha:]' | tr '[:upper:]' '[:lower:]'
}

function get_yq() {
  if ! [ -f "/tmp/yq" ]; then
    wget -q https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -O /tmp/yq
    chmod +x /tmp/yq
  fi
}

function merge_tf_vars() {
  if [ -s "$1/variables.tf" ]; then
    cat "$1/variables.tf" >> "$GITHUB_ACTION_PATH/operations/deployment/terraform/variables.tf" 
    rm "$1/variables.tf"
  fi 
  if [ -s "$1/terraform.tfvars" ]; then
    cat "$1/terraform.tfvars" >> "$GITHUB_ACTION_PATH/operations/deployment/terraform/terraform.tfvars"
    rm "$1/terraform.tfvars"
  fi 
}

### Generate incoming action repo's

if [ -n "$GH_ACTION_REPO" ]; then
  #  ANSIBLE PART - Ensure we have an incoming repo and Ansible is intended to run
  if [ -n "$GH_ACTION_INPUT_ANSIBLE" ] && [[ "$(alpha_only $ANSIBLE_SKIP)" != "true" ]]; then
    GH_ACTION_INPUT_ANSIBLE_PATH="$GH_ACTION_REPO/$GH_ACTION_INPUT_ANSIBLE"

    if [ -s "$GH_ACTION_INPUT_ANSIBLE_PATH/$GH_ACTION_INPUT_ANSIBLE_PLAYBOOK" ]; then
      get_yq

      # Create a bitops.config.yaml for Ansible plugin if none provided with the Ansible code
      if ! [ -s "$GH_ACTION_INPUT_ANSIBLE_PATH/bitops.config.yaml" ]; then
        touch "$GH_ACTION_INPUT_ANSIBLE_PATH/bitops.config.yaml"
        /tmp/yq ".ansible.cli.main-playbook = \"$GH_ACTION_INPUT_ANSIBLE_PLAYBOOK\"" -i "$GH_ACTION_INPUT_ANSIBLE_PATH/bitops.config.yaml"
      fi

      # If there is an extra vars file and not empty, add it to the config
      if [ -s "$GITHUB_WORKSPACE/$GH_DEPLOYMENT_ACTION_INPUT_ANSIBLE_EXTRA_VARS_FILE" ] && [ -n "$GH_DEPLOYMENT_ACTION_INPUT_ANSIBLE_EXTRA_VARS_FILE" ]; then
        /tmp/yq ".ansible.cli.extra-vars = \"@$(basename $GH_DEPLOYMENT_ACTION_INPUT_ANSIBLE_EXTRA_VARS_FILE)\"" -i "$GH_ACTION_INPUT_ANSIBLE_PATH/bitops.config.yaml"
        # Move incoming Ansible vars-file from end-user action
        mv "$GITHUB_WORKSPACE/$GH_DEPLOYMENT_ACTION_INPUT_ANSIBLE_EXTRA_VARS_FILE" "$GH_ACTION_INPUT_ANSIBLE_PATH/"
      fi
      # Move incoming Ansible folder from action
      mv "$GH_ACTION_INPUT_ANSIBLE_PATH" "$GITHUB_ACTION_PATH/operations/deployment/ansible/action"

      # Add Ansible - Incoming GH to main bitops.config.yaml
      if [[ "$(alpha_only $BITOPS_CODE_ONLY)" != "true" ]]; then
        /tmp/yq ".bitops.deployments.ansible/action.plugin = \"ansible\"" -i $GITHUB_ACTION_PATH/operations/deployment/bitops.config.yaml
      fi
    else
      echo "::error::Couldn't find $GH_ACTION_INPUT_ANSIBLE_PLAYBOOK inside incoming Action Ansible folder."
    fi
  fi
  
  # TERRAFORM PART
  if [ -n "$GH_ACTION_INPUT_TERRAFORM" ]; then
    echo "Action terra input"
    GH_ACTION_INPUT_TERRAFORM_PATH="$GH_ACTION_REPO/$GH_ACTION_INPUT_TERRAFORM"

    ls -lah $GH_ACTION_INPUT_TERRAFORM_PATH

#    # Create a bitops.config.yaml for Ansible plugin if none provided with the Ansible code
#    if ! [ -s "$GH_ACTION_INPUT_TERRAFORM_PATH/bitops.config.yaml" ]; then
#      touch "$GH_ACTION_INPUT_TERRAFORM_PATH/bitops.config.yaml"
#      /tmp/yq ".terraform.cli.stack-action = \"apply\"" -i "$GH_ACTION_INPUT_TERRAFORM_PATH/bitops.config.yaml"
#    fi
    merge_tf_vars "$GH_ACTION_INPUT_TERRAFORM_PATH"
    mv "${GH_ACTION_INPUT_TERRAFORM_PATH}"/* "${GITHUB_ACTION_PATH}"/operations/deployment/terraform/.


#echo -en "
#module "terraform_action" {
#  source = "./action/"
#}
#" > $GITHUB_ACTION_PATH/operations/deployment/terraform/action.tf


  fi
fi

### Generate incoming deployment repo's

#  ANSIBLE PART - Ensure we have an incoming repo and Ansible is intended to run
if [ -n "$GH_DEPLOYMENT_INPUT_ANSIBLE" ] && [[ "$(alpha_only $ANSIBLE_SKIP)" != "true" ]]; then
  GH_DEPLOYMENT_INPUT_ANSIBLE_PATH="$GITHUB_WORKSPACE/$GH_DEPLOYMENT_INPUT_ANSIBLE"

  if [ -s "$GH_DEPLOYMENT_INPUT_ANSIBLE_PATH/$GH_DEPLOYMENT_INPUT_ANSIBLE_PLAYBOOK" ]; then
    get_yq

    # Create a bitops.config.yaml for Ansible plugin if none provided with the Ansible code
    if ! [ -s "$GH_DEPLOYMENT_INPUT_ANSIBLE_PATH/bitops.config.yaml" ]; then
      touch "$GH_DEPLOYMENT_INPUT_ANSIBLE_PATH/bitops.config.yaml"
      /tmp/yq ".ansible.cli.main-playbook = \"$GH_DEPLOYMENT_INPUT_ANSIBLE_PLAYBOOK\"" -i "$GH_DEPLOYMENT_INPUT_ANSIBLE_PATH/bitops.config.yaml"
    fi

    # If there is an extra vars file and not empty, add it to the config
    if [ -s "$GITHUB_WORKSPACE/$GH_DEPLOYMENT_INPUT_ANSIBLE_EXTRA_VARS_FILE" ] && [ -n "$GH_DEPLOYMENT_INPUT_ANSIBLE_EXTRA_VARS_FILE" ]; then
      /tmp/yq ".ansible.cli.extra-vars = \"@$(basename $GH_DEPLOYMENT_INPUT_ANSIBLE_EXTRA_VARS_FILE)\"" -i "$GH_DEPLOYMENT_INPUT_ANSIBLE_PATH/bitops.config.yaml"
      # Move incoming Ansible vars-file from end-user action
      mv "$GITHUB_WORKSPACE/$GH_DEPLOYMENT_INPUT_ANSIBLE_EXTRA_VARS_FILE" "$GH_DEPLOYMENT_INPUT_ANSIBLE_PATH/"
    fi
    # Move incoming Ansible folder from deployment
    mv "$GH_DEPLOYMENT_INPUT_ANSIBLE_PATH" "$GITHUB_ACTION_PATH/operations/deployment/ansible/deployment"

    # Add Ansible - Incoming GH to main bitops.config.yaml
    if [[ "$(alpha_only $BITOPS_CODE_ONLY)" != "true" ]]; then
      /tmp/yq ".bitops.deployments.ansible/deployment.plugin = \"ansible\"" -i $GITHUB_ACTION_PATH/operations/deployment/bitops.config.yaml
    fi
  else
    echo "::error::Couldn't find $GH_DEPLOYMENT_INPUT_ANSIBLE_PLAYBOOK inside incoming Deployment Ansible folder."
  fi
fi

# TERRAFORM PART
if [ -n "$GH_DEPLOYMENT_INPUT_TERRAFORM" ]; then
  echo "Deploy terra input"

  GH_DEPLOYMENT_INPUT_TERRAFORM_PATH="$GITHUB_WORKSPACE/$GH_DEPLOYMENT_INPUT_TERRAFORM"
  
  ls -lah $GH_DEPLOYMENT_INPUT_TERRAFORM_PATH

  # Create a bitops.config.yaml for Ansible plugin if none provided with the Ansible code
  #if ! [ -s "$GH_DEPLOYMENT_INPUT_TERRAFORM_PATH/bitops.config.yaml" ]; then
  #  touch "$GH_DEPLOYMENT_INPUT_TERRAFORM_PATH/bitops.config.yaml"
  #  /tmp/yq ".terraform.cli.stack-action = \"apply\"" -i "$GH_DEPLOYMENT_INPUT_TERRAFORM_PATH/bitops.config.yaml"
  #fi

  merge_tf_vars "$GH_DEPLOYMENT_INPUT_TERRAFORM_PATH"
    mv "${GH_DEPLOYMENT_INPUT_TERRAFORM_PATH}"/* "${GITHUB_ACTION_PATH}"/operations/deployment/terraform/.

#echo -en "
#module "terraform_deployment" {
#  source = "./deployment/"
#}
#" > $GITHUB_ACTION_PATH/operations/deployment/terraform/deployment.tf

fi

    tail -n 20 "$GITHUB_ACTION_PATH/operations/deployment/terraform/variables.tf" 
    tail -n 20 "$GITHUB_ACTION_PATH/operations/deployment/terraform/terraform.tfvars"


echo "Done with generate_bitops_incoming.sh"