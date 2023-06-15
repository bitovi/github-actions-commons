#!/bin/bash

set -e

echo "In generate_bitops_incoming.sh"

### Functions

# Will clear the text for anything odd and lowercase everything. Ensuring True is true.
function alpha_only() {
  echo "$1" | tr -cd '[:alpha:]' | tr '[:upper:]' '[:lower:]'
}

# Fetch the yq tool. To be used at appending some yaml code
function get_yq() {
  if ! [ -f "/tmp/yq" ]; then
    wget -q https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -O /tmp/yq
    chmod +x /tmp/yq
  fi
}

# Will merge the incoming variables.tf and terraform.tfvars into the files of the selected folder. 
function merge_tf_vars() {
  terraform_destination="operations/deployment/terraform/$2"
  if [ -s "$1/variables.tf" ]; then
    echo "" >> "$GITHUB_ACTION_PATH/$terraform_destination/variables.tf" 
    cat "$1/variables.tf" >> "$GITHUB_ACTION_PATH/$terraform_destination/variables.tf" 
    rm "$1/variables.tf"
  fi 
  if [ -s "$1/terraform.tfvars" ]; then
    echo "" >> "$GITHUB_ACTION_PATH/$terraform_destination/terraform.tfvars"
    cat "$1/terraform.tfvars" >> "$GITHUB_ACTION_PATH/$terraform_destination/terraform.tfvars"
    rm "$1/terraform.tfvars"
  fi 
}

# Ensure we are not overwriting any file by prepending some string in the filename
function move_content_append() {
  source_folder="$1"
  prepend="$2"

  # Move files from source folder to destination folder
  find "$source_folder" -maxdepth 1 -type f -path "$source_folder/*" | while read file; do
    mv "$file" "${GITHUB_ACTION_PATH}"/operations/deployment/terraform/ec2/"$prepend"_$(basename "$file")
  done
  # Move remaining folders (if they exist) and exclude the . folder
  find "$source_folder" -maxdepth 1 -type d -not -name "." -path "$source_folder/*" | while read folder; do
    mv "$folder" "${GITHUB_ACTION_PATH}/operations/deployment/terraform/ec2/."
  done
}

### End functions


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

      # Add Ansible - Incoming GH to main bitops.config.yaml and the generated code one
      if [[ "$(alpha_only $BITOPS_CODE_ONLY)" != "true" ]]; then
        /tmp/yq ".bitops.deployments.ansible/action.plugin = \"ansible\"" -i $GITHUB_ACTION_PATH/operations/deployment/bitops.config.yaml
      fi
      /tmp/yq ".bitops.deployments.ansible/action.plugin = \"ansible\"" -i $GITHUB_ACTION_PATH/operations/generated_code/bitops.config.yaml
    else
      echo "::error::Couldn't find $GH_ACTION_INPUT_ANSIBLE_PLAYBOOK inside incoming Action Ansible folder."
    fi
  fi
  
  # TERRAFORM PART
  if [ -n "$GH_ACTION_INPUT_TERRAFORM" ]; then
    GH_ACTION_INPUT_TERRAFORM_PATH="$GH_ACTION_REPO/$GH_ACTION_INPUT_TERRAFORM"

    merge_tf_vars "$GH_ACTION_INPUT_TERRAFORM_PATH" ec2
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

    # Add Ansible - Incoming GH to main bitops.config.yaml and the generated code one
    if [[ "$(alpha_only $BITOPS_CODE_ONLY)" != "true" ]]; then
      /tmp/yq ".bitops.deployments.ansible/deployment.plugin = \"ansible\"" -i $GITHUB_ACTION_PATH/operations/deployment/bitops.config.yaml
    fi
    /tmp/yq ".bitops.deployments.ansible/deployment.plugin = \"ansible\"" -i $GITHUB_ACTION_PATH/operations/generated_code/bitops.config.yaml
  else
    echo "::error::Couldn't find $GH_DEPLOYMENT_INPUT_ANSIBLE_PLAYBOOK inside incoming Deployment Ansible folder."
  fi
fi

# TERRAFORM PART
if [ -n "$GH_DEPLOYMENT_INPUT_TERRAFORM" ]; then
  GH_DEPLOYMENT_INPUT_TERRAFORM_PATH="$GITHUB_WORKSPACE/$GH_DEPLOYMENT_INPUT_TERRAFORM"

  merge_tf_vars "$GH_DEPLOYMENT_INPUT_TERRAFORM_PATH" ec2
  move_content_append "$GH_DEPLOYMENT_INPUT_TERRAFORM_PATH" deploy
fi



### HELM Merger

if [ -n "${AWS_EKS_CLUSTER_NAME}" ]; then
  aws_eks_cluster_name="$AWS_EKS_CLUSTER_NAME"
else
  aws_eks_cluster_name="$GITHUB_IDENTIFIER-cluster"
fi

function helm_move_content_prepend() {
  source_folder="$1"
  destination_folder="$2"
  number="$3"
  find "$source_folder" -maxdepth 1 -type d -not -name "." -path "$source_folder/*" | while read chart_folder; do
  # Move files from source folder to destination folder
    chart_name=$(basename "$chart_folder")
    mkdir -p "$destination_folder/$chart_name/values-files"
    find "$chart_folder" -maxdepth 1 -type f -path "$chart_folder/*" | while read file; do
      file_name=$(basename "$file")
      echo "Filename = $file_name"
      if [[ "$file_name" == "values.yaml" ]]; then
        echo "mv $file $destination_folder/$chart_name/values-files/$3_$file_name"
        mv "$file" "$destination_folder/$chart_name/values-files/$3_$file_name"
      else
        echo "mv $file $destination_folder/$chart_name/$file_name"
        mv "$file" "$destination_folder/$chart_name/$file_name"
      fi
      touch "$destination_folder/$chart_name/bitops.config.yaml"
      if [ $(yq eval ".helm.options.release-name" "$destination_folder/$chart_name/bitops.config.yaml") == null ]; then
              /tmp/yq ".helm.options.release-name = \"$chart_name\"" -i "$destination_folder/$chart_name/bitops.config.yaml"
      fi
      /tmp/yq ".helm.options.k8s.fetch.cluster-name = \"$aws_eks_cluster_name\"" -i "$destination_folder/$chart_name/bitops.config.yaml"
    done
    # Move remaining folders (if they exist) and exclude the . folder
    find "$chart_folder" -maxdepth 1 -type d -not -name "." -path "$chart_folder/*" | while read folder; do
      echo "mv $folder $destination_folder/$chart_name/."
      mv "$folder" "$destination_folder/$chart_name/."
    done
    echo "Printing chart result"
    tree "$destination_folder/$chart_name"
    cat "$destination_folder/$chart_name/bitops.config.yaml"
  done
}

# Action charts inputs
if [[ "$(alpha_only $AWS_EKS_CREATE)" == "true" ]]; then
  get_yq
  if [ -n "$GH_ACTION_REPO" ]; then
    # HELM CHARTS PART
    if [ -n "$GH_ACTION_INPUT_HELM_CHARTS" ]; then
      GH_ACTION_INPUT_HELM_CHARTS_PATH="$GH_ACTION_REPO/$GH_ACTION_INPUT_HELM_CHARTS"
      echo "GH_ACTION_INPUT_HELM_CHARTS_PATH $GH_ACTION_INPUT_HELM_CHARTS_PATH"
      helm_move_content_prepend $GH_ACTION_INPUT_HELM_CHARTS_PATH ${GITHUB_ACTION_PATH}/operations/deployment/helm 0
    fi
  fi
  
  # Deployment charts inputs
  if [ -n "$GH_DEPLOYMENT_INPUT_HELM_CHARTS" ]; then
      GH_DEPLOYMENT_INPUT_HELM_CHARTS_PATH="$GITHUB_WORKSPACE/$GH_DEPLOYMENT_INPUT_HELM_CHARTS"
      echo "GH_DEPLOYMENT_INPUT_HELM_CHARTS_PATH $GH_DEPLOYMENT_INPUT_HELM_CHARTS_PATH"
      helm_move_content_prepend $GH_DEPLOYMENT_INPUT_HELM_CHARTS_PATH ${GITHUB_ACTION_PATH}/operations/deployment/helm 1
  fi
  
  if [[ "$(alpha_only $BITOPS_CODE_ONLY)" != "true" ]]; then
    /tmp/yq ".bitops.deployments.helm.plugin = \"helm\"" -i $GITHUB_ACTION_PATH/operations/deployment/bitops.config.yaml
  fi
  /tmp/yq ".bitops.deployments.helm.plugin = \"helm\"" -i $GITHUB_ACTION_PATH/operations/generated_code/bitops.config.yaml
  
  tree ${GITHUB_ACTION_PATH}/operations/deployment/helm
fi

cat "$destination_folder/$chart_name/bitops.config.yaml"

echo "Done with generate_bitops_incoming.sh"