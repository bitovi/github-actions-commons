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
  # Ansible - Fetch repo - Do we need an if here?
  #if [[ $(alpha_only "$AWS_EFS_CREATE") == true ]] || [[ $(alpha_only "$AWS_EFS_CREATE_HA") == true ]] ; then
  echo -en "
    ansible/clone_repo:
      plugin: ansible
  " >> $GITHUB_ACTION_PATH/operations/deployment/bitops.config.yaml
  #fi
  
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


# Generate GH Incoming pieces


echo GH_CALLING_REPO
echo $GH_CALLING_REPO
echo GH_INPUT_ANSIBLE
echo $GH_INPUT_ANSIBLE
echo "GH_CALLING_REPO/GH_INPUT_ANSIBLE"
echo "$GH_CALLING_REPO/$GH_INPUT_ANSIBLE"
echo GH_INPUT_ANSIBLE_PLAYBOOK
echo $GH_INPUT_ANSIBLE_PLAYBOOK
#GH_CALLING_REPO=$(echo $GH_CALLING_REPO | awk -F "/" '{OFS="/"; NF=7; print}')
#echo "New GH Calling Repo ----> $GH_CALLING_REPO"
ls -lah $GH_CALLING_REPO
tree $GH_CALLING_REPO
if [ -n "$GH_CALLING_REPO" ]; then
  #  ANSIBLE PART
  echo "Inside ansible part"
  if [ -n "$GH_INPUT_ANSIBLE" ] && [[ "$(alpha_only $ANSIBLE_SKIP)" != "true" ]]; then
    GH_INPUT_ANSIBLE_PATH="$GH_CALLING_REPO/$GH_INPUT_ANSIBLE"
    echo "GH_INPUT_ANSIBLE_PATH -> $GH_INPUT_ANSIBLE_PATH"
    ls -lah $GH_INPUT_ANSIBLE_PATH
    if [ -s "$GH_INPUT_ANSIBLE_PATH/$GH_INPUT_ANSIBLE_PLAYBOOK" ]; then
      ls -lah "$GH_INPUT_ANSIBLE_PATH"
  
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

      echo " --> Moving $GH_INPUT_ANSIBLE_PATH"
      mv "$GH_INPUT_ANSIBLE_PATH" "$GITHUB_ACTION_PATH/operations/deployment/ansible/incoming"

      ######### Add extra vars file here. 
      # Copying Github Ansible extra-vars file
      if [ -s "$GITHUB_WORKSPACE/$GH_INPUT_ANSIBLE_EXTRA_VARS_FILE" ] && [ -n "$GH_INPUT_ANSIBLE_EXTRA_VARS_FILE" ]; then
        cp "$GITHUB_WORKSPACE/$GH_INPUT_ANSIBLE_EXTRA_VARS_FILE" "${GITHUB_ACTION_PATH}/operations/deployment/ansible/incoming/."
        
        echo "Got into adding extra vars"
  
        boc_file="$GITHUB_ACTION_PATH/operations/deployment/ansible/incoming/bitops.config.yaml"
        extra_vars_file="$(basename $GH_INPUT_ANSIBLE_EXTRA_VARS_FILE)"
  
        # Read the value of the extra-vars parameter
        extra_vars=$(awk '/extra-vars/ {print $2}' $boc_file)
        
        # Check if extra-vars is defined
        if [[ -n "$extra_vars" ]]; then
          # If there's already a vars-file, replace it 
          value=${extra_vars##*@}
          echo "::notice::There's already an extra-vars definition. File called is: $value"
          echo "::notice::Overwriting definition with $extra_vars_file"
          sed -i 's/\(extra-vars:.*\)@'"$value"'/\1'"@$extra_vars_file"'/' $boc_file
                  echo "Got into duplicate line found"

        else
          # Append the extra-vars parameter after the main-playbook parameter
          sed -i "/main-playbook/a \\      extra-vars: \"@$extra_vars_file\"" $boc_file
                            echo "Got into NO duplicate line found"

        fi
      fi

      echo "Cating BOC File"
      cat $boc_file
      # Add Ansible - Incoming GH
echo -en "
    ansible/incoming:
      plugin: ansible
" >> $GITHUB_ACTION_PATH/operations/deployment/bitops.config.yaml
    fi
  fi
  
  # TERRAFORM PART
  # TBC
fi

echo "Cating BOC file"
cat $boc_file
exit 1
echo "Cating MAIN bitops.config.yaml"
cat $GITHUB_ACTION_PATH/operations/deployment/bitops.config.yaml