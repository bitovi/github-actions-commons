#!/bin/bash

#set -x

echo "::group::In Deploy"
GITHUB_REPO_NAME=$(echo $GITHUB_REPOSITORY | sed 's/^.*\///')

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

# Generating GitHub Variables and Secrets files
mkdir -p "${GITHUB_ACTION_PATH}/operations/deployment/env-files"
echo "$ENV_GHV" > "${GITHUB_ACTION_PATH}/operations/deployment/env-files/ghv.env"
echo "$ENV_GHS" > "${GITHUB_ACTION_PATH}/operations/deployment/env-files/ghs.env"
if [ -s "$GITHUB_WORKSPACE/$ENV_REPO" ]; then
  cp "$GITHUB_WORKSPACE/$ENV_REPO" "${GITHUB_ACTION_PATH}/operations/deployment/env-files/repo.env"
fi


# DEBUGGING --- TBD

# List terraform folder
echo "ls -al $GITHUB_ACTION_PATH/operations/deployment/terraform/"
ls -al $GITHUB_ACTION_PATH/operations/deployment/terraform/
# Prints out bitops.config.yaml
echo "cat $GITHUB_ACTION_PATH/operations/deployment/terraform/bitops.config.yaml"
cat $GITHUB_ACTION_PATH/operations/deployment/terraform/bitops.config.yaml

echo "cat GITHUB_ACTION_PATH/operations/deployment/terraform/provider.tf"
cat $GITHUB_ACTION_PATH/operations/deployment/terraform/provider.tf
echo "ls GITHUB_ACTION_PATH/operations/deployment/docker/app/${GITHUB_REPO_NAME}"
ls "$GITHUB_ACTION_PATH/operations/deployment/docker/app/${GITHUB_REPO_NAME}"


TERRAFORM_COMMAND=""
if [ "$TF_STACK_DESTROY" == "true" ]; then
  TERRAFORM_COMMAND="destroy"
  ANSIBLE_SKIP_DEPLOY="true"
fi
echo "::endgroup::"

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
-e BITOPS_ANSIBLE_SKIP_DEPLOY="${ANSIBLE_SKIP_DEPLOY}" \
-e TF_STATE_BUCKET="${TF_STATE_BUCKET}" \
-e TF_STATE_BUCKET_DESTROY="${TF_STATE_BUCKET_DESTROY}" \
-e DEFAULT_FOLDER_NAME="_default" \
-e BITOPS_FAST_FAIL="${BITOPS_FAST_FAIL}" \
-v $(echo $GITHUB_ACTION_PATH)/operations:/opt/bitops_deployment \
bitovi/bitops:dev
BITOPS_RESULT=$?
echo "::endgroup::"

exit $BITOPS_RESULT