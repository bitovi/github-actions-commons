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

function check_aws_bucket_for_file() {
  bucket="$1"
  file_key="$2"
  aws s3 ls "s3://$bucket/$file_key" --summarize &>/dev/null
  return $?
}

function check_statefile() {
  provider="$1"
  bucket="$TF_STATE_BUCKET"
  commons_module="$2"
  if [[ "$provider" == "aws" ]]; then
    check_aws_bucket_for_file $bucket "tf-state-$commons_module"
    return $?
  fi 
}

function add_terraform_module (){
    echo -en "
    terraform/$1:
      plugin: terraform
" >> $BITOPS_CONFIG_TEMP
}

function add_ansible_module (){
    echo -en "
    ansible/$1:
      plugin: ansible
" >> $BITOPS_CONFIG_TEMP
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
    - module.vpc.random_integer.az_select
    - module.vpc"
    #- module.vpc.random_integer.az_select
    #- module.vpc.aws_vpc.main
    #- 
    #- module.vpc.aws_subnet.private
    #- module.vpc.aws_subnet.public
    #- module.vpc.data.aws_availability_zones"
    #    - module.vpc.aws_vpc.default
    #- module.vpc.aws_vpc.existing
targets_attribute="$targets_attribute $targets"

#Will add the user_data file into the EC2 Terraform folder
if [[ $(alpha_only "$AWS_EC2_INSTANCE_CREATE") == true ]]; then
  if [ -s "$GITHUB_WORKSPACE/$AWS_EC2_USER_DATA_FILE" ] && [ -f "$GITHUB_WORKSPACE/$AWS_EC2_USER_DATA_FILE" ]; then
      echo "Moving $AWS_EC2_USER_DATA_FILE to be used by Terraform during EC2 creation"
      mv "$GITHUB_WORKSPACE/$AWS_EC2_USER_DATA_FILE" "$GITHUB_ACTION_PATH/operations/deployment/terraform/aws/aws_ec2_incoming_user_data_script.sh"
  fi
fi
#Will add the user_data file into the EKS Terraform folder
if [[ $(alpha_only "$AWS_EKS_CREATE") == true ]]; then
  if [ -s "$GITHUB_WORKSPACE/$AWS_EKS_INSTANCE_USER_DATA_FILE" ] && [ -f "$GITHUB_WORKSPACE/$AWS_EKS_INSTANCE_USER_DATA_FILE" ]; then
      echo "Moving $AWS_EKS_INSTANCE_USER_DATA_FILE to be used by Terraform during EKS Nodes creation"
      mv "$GITHUB_WORKSPACE/$AWS_EKS_INSTANCE_USER_DATA_FILE" "$GITHUB_ACTION_PATH/operations/deployment/terraform/eks/aws_eks_incoming_user_data_script.sh"
  fi
fi
# Below we will be creating the config file, one for the action itself, other to store as an artifact after. 

# Files Definitions
mkdir -p "${GITHUB_ACTION_PATH}/operations/generated_code"
# BitOps Deployment Config file
BITOPS_DEPLOY_FILE="${GITHUB_ACTION_PATH}/operations/deployment/bitops.config.yaml"
# BitOps Code Config File
##BITOPS_CODE_FILE="${GITHUB_ACTION_PATH}/operations/generated_code/bitops.config.yaml"
# BitOps Temp file
BITOPS_CONFIG_TEMP="/tmp/bitops.config.yaml"

# Global Bitops Config
echo -en "
bitops:
  deployments:
" > $BITOPS_DEPLOY_FILE

# BitOps Config Temp file
  # Terraform - Generate infra
  # Will check if there is a tf-state file to work with. If so, will create a destroy step.
  if [[ $(alpha_only "$TF_STACK_DESTROY") == true ]]; then 
    if check_statefile aws aws; then
      add_terraform_module aws
      create_bitops_terraform_config aws false targets
    fi
  else
    if [[ $(alpha_only "$AWS_EC2_INSTANCE_CREATE") == true ]] || [[ $(alpha_only "$AWS_EFS_CREATE") == true ]] || [[ "$AWS_AURORA_ENABLE" != "" ]]; then
      add_terraform_module aws
      create_bitops_terraform_config aws true targets
    fi
  fi
  if [[ $(alpha_only "$AWS_EKS_CREATE") != true ]]; then
    if check_statefile aws eks; then
      add_terraform_module eks
      create_bitops_terraform_config eks false
    fi
  else
    if [[ $(alpha_only "$AWS_EKS_CREATE") == true ]]; then
      add_terraform_module eks
      create_bitops_terraform_config eks true
    fi
  fi
  
  # Ansible Code part

  if [[ "$(alpha_only $ANSIBLE_SKIP)" != "true" ]] && [[ "$(alpha_only $AWS_EC2_INSTANCE_CREATE)" == "true" ]] && [[ "$(alpha_only $AWS_EC2_INSTANCE_PUBLIC_IP)" == "true" ]]; then
    # Ansible - Docker cleanup
    if [[ $(alpha_only "$DOCKER_FULL_CLEANUP") == true ]]; then
      add_ansible_module docker_cleanup
    fi
    # Ansible - Instance cleanup
    if [[ $(alpha_only "$DOCKER_REPO_APP_DIRECTORY_CLEANUP") == true ]]; then
      add_ansible_module ec2_cleanup
    fi
    # Ansible - Fetch repo
    add_ansible_module clone_repo
    # Ansible - Install EFS
    if [[ $(alpha_only "$AWS_EFS_CREATE") == true ]] || [[ $(alpha_only "$AWS_EFS_CREATE_HA") == true ]] || [[ "$AWS_EFS_MOUNT_ID" != "" ]]; then
      add_ansible_module efs
    fi
    # Ansible - Install Docker
    if [[ $(alpha_only "$DOCKER_INSTALL") == true ]]; then
      add_ansible_module docker
    fi
  fi

# Helm part

if [ ! -s "$BITOPS_CONFIG_TEMP" ]; then
  rm $BITOPS_DEPLOY_FILE
 else
  cat $BITOPS_CONFIG_TEMP >> $BITOPS_DEPLOY_FILE
  rm $BITOPS_CONFIG_TEMP
fi

echo "Done with generate_bitops_config.sh"
exit 0