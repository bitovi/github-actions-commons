#!/bin/bash

#set -x

# Removes anything from the variable and leave only alpha characters, and lowers them. This is to validate if boolean.
function alpha_only() {
    echo "$1" | tr -cd '[:alpha:]' | tr '[:upper:]' '[:lower:]'
}

echo "::group::In Deploy"
GITHUB_REPO_NAME=$(echo $GITHUB_REPOSITORY | sed 's/^.*\///')

# Ensuring variable is set to true
if [ "$(alpha_only $ANSIBLE_SKIP)" == "true" ]; then
  ANSIBLE_SKIP="true"
fi

# Validating if Terraform is set to destroy, and avoid Ansible
TERRAFORM_COMMAND=""
if [ "$(alpha_only $TF_STACK_DESTROY)" == "true" ]; then
  TERRAFORM_COMMAND="destroy"
  ANSIBLE_SKIP="true"
fi

# Adding global EFS flag
if [[ $(alpha_only "$AWS_EFS_CREATE") == true ]] || [[ $(alpha_only "$AWS_EFS_CREATE_HA") == true ]] || [ -n "$AWS_EFS_FS_ID" ]; then 
  export AWS_EFS_ENABLE="true"
else
  export AWS_EFS_ENABLE="" # Intentional, being consistent with the rest of incoming vars
fi

# Generate Github identifiers vars
export GITHUB_IDENTIFIER="$($GITHUB_ACTION_PATH/operations/_scripts/generate/generate_identifier.sh)"
export GITHUB_IDENTIFIER_SS="$($GITHUB_ACTION_PATH/operations/_scripts/generate/generate_identifier.sh 30)"

# Generate buckets identifiers and check them agains AWS Rules 
export TF_STATE_BUCKET="$(/bin/bash $GITHUB_ACTION_PATH/operations/_scripts/generate/generate_buckets_identifiers.sh tf | xargs)"
/bin/bash $GITHUB_ACTION_PATH/operations/_scripts/deploy/check_bucket_name.sh $TF_STATE_BUCKET
export AWS_ELB_ACCESS_LOG_BUCKET_NAME="$(/bin/bash $GITHUB_ACTION_PATH/operations/_scripts/generate/generate_buckets_identifiers.sh lb | xargs)"
/bin/bash $GITHUB_ACTION_PATH/operations/_scripts/deploy/check_bucket_name.sh $AWS_ELB_ACCESS_LOG_BUCKET_NAME

# Generate the provider.tf file
/bin/bash $GITHUB_ACTION_PATH/operations/_scripts/generate/generate_provider.sh

# Generate terraform variables
/bin/bash $GITHUB_ACTION_PATH/operations/_scripts/generate/generate_vars_terraform.sh

# Generate app repo
/bin/bash $GITHUB_ACTION_PATH/operations/_scripts/generate/generate_app_repo.sh ansible/clone_repo

# Generate bitops config
/bin/bash $GITHUB_ACTION_PATH/operations/_scripts/generate/generate_bitops_config.sh
# If nothing was generated, then we don't have an instance or cluster to connect. Exit.
if [ ! -s "$GITHUB_ACTION_PATH/operations/deployment/bitops.config.yaml" ]; then
  echo "There is nothing to be created or destroyed. Exiting."
  exit 0
fi

# Generate bitops incoming repos config if any
/bin/bash $GITHUB_ACTION_PATH/operations/_scripts/generate/generate_bitops_incoming.sh

# Generate bitops incoming repos config
if [ -n "$GH_ACTION_REPO" ] && [ -n "$BITOPS_EXTRA_ENV_VARS_FILE" ]; then
  if [ -s $GH_ACTION_REPO/$BITOPS_EXTRA_ENV_VARS_FILE ]; then
    cat $GH_ACTION_REPO/$BITOPS_EXTRA_ENV_VARS_FILE
    BITOPS_EXTRA_ENV_VARS_FILE="--env-file $GH_ACTION_REPO/$BITOPS_EXTRA_ENV_VARS_FILE"
  else
    echo "File $BITOPS_EXTRA_ENV_VARS_FILE missing or empty"
  fi
fi

echo "Final BitOps config file"
cat $GITHUB_ACTION_PATH/operations/deployment/bitops.config.yaml

## Ensuring bucket get's destroyed only if everything is set to be destroyed
if [[ $(alpha_only "$TF_STATE_BUCKET_DESTROY") == true ]] && ! [[ $(alpha_only "$TF_STACK_DESTROY") == true ]] ; then
  if [[ $(alpha_only "$AWS_AURORA_ENABLE") == true ]] || 
     [[ $(alpha_only "$AWS_RDS_DB_ENABLE") == true ]] || 
     [[ $(alpha_only "$AWS_EFS_ENABLE") == true ]] || 
     [[ $(alpha_only "$AWS_EC2_INSTANCE_CREATE") == true ]] ||
     [[ $(alpha_only "$AWS_ECS_ENABLE") == true ]] || 
     [[ $(alpha_only "$AWS_DB_PROXY_ENABLE") == true ]] ||
     [[ $(alpha_only "$AWS_REDIS_ENABLE") == true ]] ||
     [[ $(alpha_only "$AWS_ECR_REPO_CREATE") == true ]] ||
     [[ $(alpha_only "$AWS_EKS_CREATE") == true ]]; then 
    export TF_STATE_BUCKET_DESTROY="false"
  fi
fi

# Generating GitHub Variables and Secrets files
mkdir -p "${GITHUB_ACTION_PATH}/operations/deployment/env-files"
echo "$ENV_GHV" > "${GITHUB_ACTION_PATH}/operations/deployment/env-files/ghv.env"
echo "$ENV_GHS" > "${GITHUB_ACTION_PATH}/operations/deployment/env-files/ghs.env"
if [ -s "$GITHUB_WORKSPACE/$ENV_REPO" ] && [ -n "$ENV_REPO" ]; then
  cp "$GITHUB_WORKSPACE/$ENV_REPO" "${GITHUB_ACTION_PATH}/operations/deployment/env-files/repo.env"
fi

# Bypass all the 'BITOPS_' ENV vars to docker
for i in $(env | grep BITOPS_); do
  BITOPS_EXTRA_ENV_VARS="${BITOPS_EXTRA_ENV_VARS} -e ${i}"
done

if [[ $(alpha_only "$BITOPS_CODE_ONLY") == "true" ]]; then
   exit 0
fi

if [[ $(alpha_only "$BITOPS_SKIP_RUN") == true ]]; then
  echo "BitOps skip run is set to true. Reached end of the line."
  exit 0
fi

echo "::group::BitOps Excecution"  
echo "Running BitOps for env: $BITOPS_ENVIRONMENT"
docker run --rm --name bitops \
-e AWS_ACCESS_KEY_ID="${AWS_ACCESS_KEY_ID}" \
-e AWS_SECRET_ACCESS_KEY="${AWS_SECRET_ACCESS_KEY}" \
-e AWS_SESSION_TOKEN="${AWS_SESSION_TOKEN}" \
-e AWS_DEFAULT_REGION="${AWS_DEFAULT_REGION}" \
-e SKIP_DEPLOY_TERRAFORM="${SKIP_DEPLOY_TERRAFORM}" \
-e SKIP_DEPLOY_HELM="${SKIP_DEPLOY_HELM}" \
-e TF_STATE_BUCKET="${TF_STATE_BUCKET}" \
-e TF_STATE_BUCKET_DESTROY="${TF_STATE_BUCKET_DESTROY}" \
-e DEFAULT_FOLDER_NAME="_default" \
${BITOPS_EXTRA_ENV_VARS_FILE} \
${BITOPS_EXTRA_ENV_VARS} \
-v $(echo $GITHUB_ACTION_PATH)/operations:/opt/bitops_deployment \
bitovi/bitops:2.6.0
BITOPS_RESULT=$?
echo "::endgroup::"

exit $BITOPS_RESULT