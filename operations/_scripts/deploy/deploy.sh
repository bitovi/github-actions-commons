#!/bin/bash

#set -x

# Removes anything from the variable and leave only alpha characters, and lowers them. This is to validate if boolean.
function alpha_only() {
    echo "$1" | tr -cd '[:alpha:]' | tr '[:upper:]' '[:lower:]'
}

echo "::group::In Deploy"
GITHUB_REPO_NAME=$(echo $GITHUB_REPOSITORY | sed 's/^.*\///')

# Validating if Terraform is set to destroy, and avoid Ansible
TERRAFORM_COMMAND=""
if [ "$(alpha_only $TF_STACK_DESTROY)" == "true" ]; then
  TERRAFORM_COMMAND="destroy"
  ANSIBLE_SKIP="true"
  if [ "$(alpha_only $AWS_EC2_INSTANCE_PROTECT)" == "true" ] && [ "$(alpha_only $AWS_EC2_INSTANCE_CREATE)" == "true" ]; then
    echo "::error:: You need to set aws_ec2_instance_protect to false before before destroying infrastructure."
    exit 1
  fi
  if [ "$(alpha_only $AWS_POSTGRES_DATABASE_PROTECTION)" == "true" ]; then
    echo "::error:: Database protection enabled. Disable it before destroying."
    exit 1
  fi
  if [ "$(alpha_only $AWS_EFS_VOLUME_PRESERVE)" == "true" ]; then
    echo "::info:: There is no real EFS protection to enable. Just a flag we created to avoid unintentional deletion."
    echo "::error:: EFS volume protection enabled. Disable it before destroying."
    exit 1
  fi
fi

if [ "$(alpha_only $AWS_EFS_VOLUME_PRESERVE)" == "true" ]; then
  echo "::info:: There is no real EFS protection to enable from AWS."
  echo "::info:: This is just a flag we created to avoid unintentional deletion on destruction."
fi

if [ "$(alpha_only $ANSIBLE_SKIP)" == "true" ]; then
  ANSIBLE_SKIP="true"
fi

# Generate buckets identifiers and check them agains AWS Rules 
export TF_STATE_BUCKET="$(/bin/bash $GITHUB_ACTION_PATH/operations/_scripts/generate/generate_buckets_identifiers.sh tf | xargs)"
/bin/bash $GITHUB_ACTION_PATH/operations/_scripts/deploy/check_bucket_name.sh $TF_STATE_BUCKET
export LB_LOGS_BUCKET="$(/bin/bash $GITHUB_ACTION_PATH/operations/_scripts/generate/generate_buckets_identifiers.sh lb | xargs)"
/bin/bash $GITHUB_ACTION_PATH/operations/_scripts/deploy/check_bucket_name.sh $LB_LOGS_BUCKET

# Generate the provider.tf file
/bin/bash $GITHUB_ACTION_PATH/operations/_scripts/generate/generate_provider.sh

# Generate terraform variables
/bin/bash $GITHUB_ACTION_PATH/operations/_scripts/generate/generate_vars_terraform.sh

# Generate app repo
/bin/bash $GITHUB_ACTION_PATH/operations/_scripts/generate/generate_app_repo.sh ansible/clone_repo
#/bin/bash $GITHUB_ACTION_PATH/operations/_scripts/generate/generate_app_repo.sh ansible/docker
#/bin/bash $GITHUB_ACTION_PATH/operations/_scripts/generate/generate_app_repo.sh ansible/efs

# Generate bitops config
/bin/bash $GITHUB_ACTION_PATH/operations/_scripts/generate/generate_bitops_config.sh

# Generate bitops incoming repos config
if [ -n "$GH_ACTION_REPO" ]; then
  if [ -n "$GH_ACTION_INPUT_TERRAFORM" ] || [ -n "$GH_ACTION_INPUT_ANSIBLE" ]; then
    /bin/bash $GITHUB_ACTION_PATH/operations/_scripts/generate/generate_bitops_incoming.sh
  fi
  # Generating incoming extra_vars_file if it exists
  if [ -n "$BITOPS_EXTRA_ENV_VARS_FILE" ]; then
    if [ -s $GH_ACTION_REPO/$BITOPS_EXTRA_ENV_VARS_FILE ]; then
      BITOPS_EXTRA_ENV_VARS_FILE="--env-file $GH_ACTION_REPO/$BITOPS_EXTRA_ENV_VARS_FILE"
      cat $GH_ACTION_REPO/$BITOPS_EXTRA_ENV_VARS_FILE
    else
      echo "File $BITOPS_EXTRA_ENV_VARS_FILE missing or empty"
    fi
  fi
fi

# Generating GitHub Variables and Secrets files
mkdir -p "${GITHUB_ACTION_PATH}/operations/deployment/env-files"
echo "$ENV_GHV" > "${GITHUB_ACTION_PATH}/operations/deployment/env-files/ghv.env"
echo "$ENV_GHS" > "${GITHUB_ACTION_PATH}/operations/deployment/env-files/ghs.env"
if [ -s "$GITHUB_WORKSPACE/$ENV_REPO" ] && [ -n "$ENV_REPO" ]; then
  cp "$GITHUB_WORKSPACE/$ENV_REPO" "${GITHUB_ACTION_PATH}/operations/deployment/env-files/repo.env"
fi

if [[ $SKIP_BITOPS_RUN == "true" ]]; then
  exit 1
fi

echo "::group::BitOps Excecution"  
echo "Running BitOps for env: $BITOPS_ENVIRONMENT"
docker run --rm --name bitops \
-e AWS_ACCESS_KEY_ID="${AWS_ACCESS_KEY_ID}" \
-e AWS_SECRET_ACCESS_KEY="${AWS_SECRET_ACCESS_KEY}" \
-e AWS_SESSION_TOKEN="${AWS_SESSION_TOKEN}" \
-e AWS_DEFAULT_REGION="${AWS_DEFAULT_REGION}" \
-e BITOPS_ENVIRONMENT="${BITOPS_ENVIRONMENT}" \
-e SKIP_DEPLOY_TERRAFORM="${SKIP_DEPLOY_TERRAFORM}" \
-e SKIP_DEPLOY_HELM="${SKIP_DEPLOY_HELM}" \
-e BITOPS_TERRAFORM_COMMAND="${TERRAFORM_COMMAND}" \
-e BITOPS_ANSIBLE_SKIP_DEPLOY="${ANSIBLE_SKIP}" \
-e TF_STATE_BUCKET="${TF_STATE_BUCKET}" \
-e TF_STATE_BUCKET_DESTROY="${TF_STATE_BUCKET_DESTROY}" \
-e DEFAULT_FOLDER_NAME="_default" \
-e BITOPS_FAST_FAIL="${BITOPS_FAST_FAIL}" \
${BITOPS_EXTRA_ENV_VARS_FILE} \
${BITOPS_EXTRA_ENV_VARS} \
-v $(echo $GITHUB_ACTION_PATH)/operations:/opt/bitops_deployment \
bitovi/bitops:2.5.0
BITOPS_RESULT=$?
echo "::endgroup::"

exit $BITOPS_RESULT