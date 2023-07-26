#!/bin/bash

set -e


echo "BitOps Ansible before script: Merge Terraform Enviornment Variables..."

ANSIBLE_DIR=ansible/clone_repo
TERRAFORM_PATH=terraform/aws

# Merging order
order=ec2,efs,postgres,repo,ghv,ghs,aws

# Ansible dotenv file -> The final destination of all
ENV_OUT_FILE="${BITOPS_ENVROOT}/${ANSIBLE_DIR}/app.env"

# TF dotenv file
ENV_EC2_FILE="${BITOPS_ENVROOT}/${TERRAFORM_PATH}/ec2.env"

# EFS dotenv file
ENV_EFS_FILE="${BITOPS_ENVROOT}/${TERRAFORM_PATH}/efs.env"

# Postgres dotenv file
ENV_POSTGRES_FILE="${BITOPS_ENVROOT}/${TERRAFORM_PATH}/postgres.env"

# Repo env file
ENV_REPO_FILE="${BITOPS_ENVROOT}/env-files/repo.env"

# GH Variables env file
ENV_GHV_FILE="${BITOPS_ENVROOT}/env-files/ghv.env"

# GH Secrets  env file
ENV_GHS_FILE="${BITOPS_ENVROOT}/env-files/ghs.env"

# TF AWS dotenv file
ENV_AWS_SECRET_FILE="${BITOPS_ENVROOT}/${TERRAFORM_PATH}/aws.env"

# Make sure app.env is empty, if not, delete it and create one.

if [ -f $ENV_OUT_FILE ]; then 
  rm -rf $ENV_OUT_FILE
fi 
touch $ENV_OUT_FILE

# Function to merge to destination

function merge {
  if [ -s $1 ]; then
    echo "Merging $2 envs"
    cat $1 >> $ENV_OUT_FILE
  else
    echo "Nothing to merge from $2"
  fi
}

# Function to be called based on the input string
function process {
  case $1 in
    aws)
      # Code to be executed for option1
      merge $ENV_AWS_SECRET_FILE "AWS Secret"
      ;;
    repo)
      # Code to be executed for option2
      merge $ENV_REPO_FILE "checked-in"
      ;;
    ghv)
      # Code to be executed for option3
      merge $ENV_GHV_FILE "GH-Vars"
      ;;
    ghs)
      # Code to be executed for option4
      merge $ENV_GHS_FILE "GH-Secret"
      ;;
    ec2)
      # Code to be executed for option5
      merge $ENV_EC2_FILE "EC2"
      ;;
    efs)
      # Code to be executed for option6
      merge $ENV_EFS_FILE "EFS"
      ;;
    postgres)
      # Code to be executed for option6
      merge $ENV_POSTGRES_FILE "Postgres"
      ;;
    *)
      # Code to be executed if no matching option is found
      echo "Invalid option"
      ;;
  esac
}

# Read the input string and split it into an array
IFS=',' read -r -a options <<< "$order"

# Loop through the array and call the process function for each element
if [ "$BITOPS_TERRAFORM_COMMAND" != "destroy" ]; then
  for option in "${options[@]}"; do
    process "$option"
  done
fi