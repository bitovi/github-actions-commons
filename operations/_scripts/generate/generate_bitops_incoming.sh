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
    echo "" >> "$GITHUB_ACTION_PATH/operations/deployment/terraform/variables.tf" 
    cat "$1/variables.tf" >> "$GITHUB_ACTION_PATH/operations/deployment/terraform/variables.tf" 
    rm "$1/variables.tf"
  fi 
  if [ -s "$1/terraform.tfvars" ]; then
    echo "" >> "$GITHUB_ACTION_PATH/operations/deployment/terraform/terraform.tfvars"
    cat "$1/terraform.tfvars" >> "$GITHUB_ACTION_PATH/operations/deployment/terraform/terraform.tfvars"
    rm "$1/terraform.tfvars"
  fi 
}

function move_content_append() {
  source_folder="$1"
  prepend="$2"

  # Move files from source folder to destination folder
  find "$source_folder" -maxdepth 1 -type f -path "$source_folder/*" | while read file; do
    mv "$file" "${GITHUB_ACTION_PATH}"/operations/deployment/terraform/"$prepend"_$(basename "$file")
  done
  # Move remaining folders (if they exist) and exclude the . folder
  find "$source_folder" -maxdepth 1 -type d -not -name "." -path "$source_folder/*" | while read folder; do
    mv "$folder" "${GITHUB_ACTION_PATH}/operations/deployment/terraform/."
  done
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
    GH_ACTION_INPUT_TERRAFORM_PATH="$GH_ACTION_REPO/$GH_ACTION_INPUT_TERRAFORM"

    merge_tf_vars "$GH_ACTION_INPUT_TERRAFORM_PATH"
    move_content_append "$GH_ACTION_INPUT_TERRAFORM_PATH" action
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
  GH_DEPLOYMENT_INPUT_TERRAFORM_PATH="$GITHUB_WORKSPACE/$GH_DEPLOYMENT_INPUT_TERRAFORM"

  merge_tf_vars "$GH_DEPLOYMENT_INPUT_TERRAFORM_PATH"
  move_content_append "$GH_DEPLOYMENT_INPUT_TERRAFORM_PATH" deploy
fi

echo "Done with generate_bitops_incoming.sh"