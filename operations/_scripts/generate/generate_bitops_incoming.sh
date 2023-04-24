#!/bin/bash

set -e

echo "In generate_bitops_incoming.sh"

function alpha_only() {
  echo "$1" | tr -cd '[:alpha:]' | tr '[:upper:]' '[:lower:]'
}

### Generate incoming repo's

if [ -n "$GH_ACTION_REPO" ]; then
  #  ANSIBLE PART - Ensure we have an incoming repo and Ansible is intended to run
  if [ -n "$GH_ACTION_INPUT_ANSIBLE" ] && [[ "$(alpha_only $ANSIBLE_SKIP)" != "true" ]]; then
    GH_ACTION_INPUT_ANSIBLE_PATH="$GH_ACTION_REPO/$GH_ACTION_INPUT_ANSIBLE"

    if [ -s "$GH_ACTION_INPUT_ANSIBLE_PATH/$GH_ACTION_INPUT_ANSIBLE_PLAYBOOK" ]; then
      # Get yq to parse and manipulate any yaml
      wget -q https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -O /tmp/yq && chmod +x /tmp/yq

      # Create a bitops.config.yaml for Ansible plugin if none provided with the Ansible code
      if ! [ -s "$GH_ACTION_INPUT_ANSIBLE_PATH/bitops.config.yaml" ]; then
        touch "$GH_ACTION_INPUT_ANSIBLE_PATH/bitops.config.yaml"
        /tmp/yq ".ansible.cli.main-playbook = \"$GH_ACTION_INPUT_ANSIBLE_PLAYBOOK\"" -i "$GH_ACTION_INPUT_ANSIBLE_PATH/bitops.config.yaml"
      fi

      # If there is an extra vars file and not empty, add it to the config
      if [ -s "$GITHUB_WORKSPACE/$GH_DEPLOYMENT_ANSIBLE_ACTION_EXTRA_VARS_FILE" ] && [ -n "$GH_DEPLOYMENT_ANSIBLE_ACTION_EXTRA_VARS_FILE" ]; then
        /tmp/yq ".ansible.cli.extra-vars = \"@$(basename $GH_DEPLOYMENT_ANSIBLE_ACTION_EXTRA_VARS_FILE)\"" -i "$GH_ACTION_INPUT_ANSIBLE_PATH/bitops.config.yaml"
        # Move incoming Ansible folder from proxy action
        mv "$GH_ACTION_INPUT_ANSIBLE_PATH" "$GITHUB_ACTION_PATH/operations/deployment/ansible/incoming"
        # Move incoming Ansible vars-file from end-user action
        mv "$GITHUB_WORKSPACE/$GH_DEPLOYMENT_ANSIBLE_ACTION_EXTRA_VARS_FILE" "${GITHUB_ACTION_PATH}/operations/deployment/ansible/incoming/."
      else
        # Move incoming Ansible folder from proxy action
        mv "$GH_ACTION_INPUT_ANSIBLE_PATH" "$GITHUB_ACTION_PATH/operations/deployment/ansible/incoming"
      fi
      # Add Ansible - Incoming GH to main bitops.config.yaml
      if [[ "$(alpha_only $BITOPS_CODE_ONLY)" != "true" ]]; then
        /tmp/yq ".bitops.deployments.ansible/incoming.plugin = \"ansible\"" -i $GITHUB_ACTION_PATH/operations/deployment/bitops.config.yaml
      fi
    else
      echo "::error::Couldn't find $GH_ACTION_INPUT_ANSIBLE_PLAYBOOK inside incoming Ansible folder."
    fi
  fi
  
  # TERRAFORM PART
  # TBC
fi

echo "Done with generate_bitops_incoming.sh"
