#!/bin/bash

set -e

echo "In generate_bitops_config.sh"

### Functions
function alpha_only() {
  echo "$1" | tr -cd '[:alpha:]' | tr '[:upper:]' '[:lower:]'
}

function create_bitops_terraform_config() {
  if [[ $(alpha_only "$2") == true ]] && ! [[ $(alpha_only "$TF_STACK_DESTROY") == true ]] ; then
    action="apply"
  else
    action="destroy"
  fi
  if [[ $(alpha_only "$3") == targets ]]; then
    add_targets="$targets_attribute"
  else
    add_targets=""
  fi

  echo -en "
terraform:
  cli:
    stack-action: "$action"
    $add_targets
  options: {}
" > $GITHUB_ACTION_PATH/operations/deployment/terraform/$1/bitops.config.yaml
}

### End functions

if [[ "$(alpha_only $TF_STACK_DESTROY)" == "true" ]]; then
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

#Will create bitops.config.yaml for that terraform folder
create_bitops_terraform_config rds $AWS_POSTGRES_ENABLE
create_bitops_terraform_config efs $AWS_EFS_ENABLE
create_bitops_terraform_config ec2 $AWS_EC2_INSTANCE_CREATE targets
create_bitops_terraform_config eks $AWS_EKS_CREATE

#Will add the user_data file into the EC2 Terraform folder
if [[ $(alpha_only "$AWS_EC2_INSTANCE_CREATE") == true ]]; then
  if [ -s "$GITHUB_WORKSPACE/$AWS_EC2_USER_DATA_FILE" ] && [ -f "$GITHUB_WORKSPACE/$AWS_EC2_USER_DATA_FILE" ]; then
      echo "Moving $AWS_EC2_USER_DATA_FILE to be used by Terraform during EC2 creation"
      mv "$GITHUB_WORKSPACE/$AWS_EC2_USER_DATA_FILE" "$GITHUB_ACTION_PATH/operations/deployment/terraform/ec2/aws_ec2_incoming_user_data_script.sh"
  fi
fi
#Will add the user_data file into the EKS Terraform folder
if [[ $(alpha_only "$AWS_EKS_CREATE") == true ]]; then
  if [ -s "$GITHUB_WORKSPACE/$AWS_EKS_USER_DATA_FILE" ] && [ -f "$GITHUB_WORKSPACE/$AWS_EKS_USER_DATA_FILE" ]; then
      echo "Moving $AWS_EKS_USER_DATA_FILE to be used by Terraform during EKS Nodes creation"
      mv "$GITHUB_WORKSPACE/$AWS_EKS_USER_DATA_FILE" "$GITHUB_ACTION_PATH/operations/deployment/terraform/eks/aws_eks_incoming_user_data_script.sh"
  fi
fi
# Below we will be creating the config file, one for the action itself, other to store as an artifact after. 

# Files Definitions
mkdir -p "${GITHUB_ACTION_PATH}/operations/generated_code"
# BitOps Deployment Config file
BITOPS_DEPLOY_FILE="${GITHUB_ACTION_PATH}/operations/deployment/bitops.config.yaml"
# BitOps Code Config File
BITOPS_CODE_FILE="${GITHUB_ACTION_PATH}/operations/generated_code/bitops.config.yaml"
# BitOps Temp file
BITOPS_CONFIG_TEMP="/tmp/bitops.config.yaml"

# Global Bitops Config
echo -en "
bitops:
  deployments:
    generators:
      plugin: terraform
" > $BITOPS_DEPLOY_FILE

# BitOps Generated Code
echo -en "
bitops:
  deployments:
" > $BITOPS_CODE_FILE

# BitOps Config Temp file
  # If to add ec2 in the begginning or the end, depending on aplly or destroy. 
  if [[ $(alpha_only "$AWS_EC2_INSTANCE_CREATE") == true ]] && [[ $(alpha_only "$AWS_EFS_ENABLE") == true ]] && ! [[ $(alpha_only "$TF_STACK_DESTROY") == true ]] ; then
  # Terraform - Generate infra
    echo -en "
    terraform/rds:
      plugin: terraform
    terraform/efs:
      plugin: terraform
    terraform/eks:
      plugin: terraform
    terraform/ec2:
      plugin: terraform
" >> $BITOPS_CONFIG_TEMP
  else
    echo -en "
    terraform/ec2:
      plugin: terraform
    terraform/eks:
      plugin: terraform
    terraform/rds:
      plugin: terraform
    terraform/efs:
      plugin: terraform
" >> $BITOPS_CONFIG_TEMP
  fi
  # Ansible Code part

  if [[ "$(alpha_only $ANSIBLE_SKIP)" != "true" ]] && [[ "$(alpha_only $AWS_EC2_INSTANCE_CREATE)" == "true" ]] && [[ "$(alpha_only $AWS_EC2_INSTANCE_PUBLIC_IP)" == "true" ]]; then
    # Ansible - Docker cleanup
    if [[ $(alpha_only "$DOCKER_FULL_CLEANUP") == true ]]; then
        echo -en "
    ansible/docker_cleanup:
      plugin: ansible
" >> $BITOPS_CONFIG_TEMP
    fi

    # Ansible - Instance cleanup
    if [[ $(alpha_only "$DOCKER_REPO_APP_DIRECTORY_CLEANUP") == true ]]; then
        echo -en "
    ansible/ec2_cleanup:
      plugin: ansible
" >> $BITOPS_CONFIG_TEMP
    fi

    # Ansible - Fetch repo
    echo -en "
    ansible/clone_repo:
      plugin: ansible
" >> $BITOPS_CONFIG_TEMP
    
    # Ansible - Install EFS
    if [[ $(alpha_only "$AWS_EFS_CREATE") == true ]] || [[ $(alpha_only "$AWS_EFS_CREATE_HA") == true ]] || [[ "$AWS_EFS_MOUNT_ID" != "" ]]; then
    echo -en "
    ansible/efs:
      plugin: ansible
" >> $BITOPS_CONFIG_TEMP
    fi
    
    # Ansible - Install Docker
    if [[ $(alpha_only "$DOCKER_INSTALL") == true ]]; then
    echo -en "
    ansible/docker:
      plugin: ansible
" >> $BITOPS_CONFIG_TEMP
    fi
  fi

if [[ "$(alpha_only $BITOPS_CODE_ONLY)" != "true" ]]; then
  cat $BITOPS_CONFIG_TEMP >> $BITOPS_DEPLOY_FILE
fi
cat $BITOPS_CONFIG_TEMP >> $BITOPS_CODE_FILE
rm $BITOPS_CONFIG_TEMP

echo "Done with generate_bitops_config.sh"