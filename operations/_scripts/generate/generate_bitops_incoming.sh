#!/bin/bash

set -e

echo "In generate_bitops_incoming.sh"

function alpha_only() {
  echo "$1" | tr -cd '[:alpha:]' | tr '[:upper:]' '[:lower:]'
}

### Generate incoming repo's

if [ -n "$GH_CALLING_REPO" ]; then
  #  ANSIBLE PART - Ensure we have an incoming repo and Ansible is intended to run
  if [ -n "$GH_INPUT_ANSIBLE" ] && [[ "$(alpha_only $ANSIBLE_SKIP)" != "true" ]]; then
    GH_INPUT_ANSIBLE_PATH="$GH_CALLING_REPO/$GH_INPUT_ANSIBLE"

    if [ -s "$GH_INPUT_ANSIBLE_PATH/$GH_INPUT_ANSIBLE_PLAYBOOK" ]; then
      # Get yq to parse and manipulate any yaml
      wget -q https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -O /tmp/yq && chmod +x /tmp/yq

      # Create a bitops.config.yaml for Ansible plugin if none provided with the Ansible code
      if ! [ -s "$GH_INPUT_ANSIBLE_PATH/bitops.config.yaml" ]; then
        touch "$GH_INPUT_ANSIBLE_PATH/bitops.config.yaml"
        /tmp/yq ".ansible.cli.main-playbook = \"$GH_INPUT_ANSIBLE_PLAYBOOK\"" -i "$GH_INPUT_ANSIBLE_PATH/bitops.config.yaml"
      fi

      # If there is an extra vars file and not empty, add it to the config
      if [ -s "$GITHUB_WORKSPACE/$GH_INPUT_ANSIBLE_EXTRA_VARS_FILE" ] && [ -n "$GH_INPUT_ANSIBLE_EXTRA_VARS_FILE" ]; then
        /tmp/yq ".ansible.cli.extra-vars = \"@$(basename $GH_INPUT_ANSIBLE_EXTRA_VARS_FILE)\"" -i "$GH_INPUT_ANSIBLE_PATH/bitops.config.yaml"
        # Move incoming Ansible folder from proxy action
        mv "$GH_INPUT_ANSIBLE_PATH" "$GITHUB_ACTION_PATH/operations/deployment/ansible/incoming"
        # Move incoming Ansible vars-file from end-user action
        mv "$GITHUB_WORKSPACE/$GH_INPUT_ANSIBLE_EXTRA_VARS_FILE" "${GITHUB_ACTION_PATH}/operations/deployment/ansible/incoming/."
      else
        # Move incoming Ansible folder from proxy action
        mv "$GH_INPUT_ANSIBLE_PATH" "$GITHUB_ACTION_PATH/operations/deployment/ansible/incoming"
      fi
      # Add Ansible - Incoming GH to main bitops.config.yaml
      /tmp/yq ".bitops.deployments.ansible/incoming.plugin = \"ansible\"" -i $GITHUB_ACTION_PATH/operations/deployment/bitops.config.yaml
    else
      echo "::error::Couldn't find $GH_INPUT_ANSIBLE_PLAYBOOK inside incoming Ansible folder."
    fi
  fi
  
  # TERRAFORM PART
  # TBC
fi