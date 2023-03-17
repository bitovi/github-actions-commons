#!/bin/bash

set -e


echo "In generate_gh_env.sh"

echo "$ENV_GHV" > "${GITHUB_ACTION_PATH}/operations/deployment/ansible/ghv.env"
echo "$ENV_GHS" > "${GITHUB_ACTION_PATH}/operations/deployment/ansible/ghs.env"