#!/bin/bash

set -e

echo "In generate_app_repo.sh"
GITHUB_REPO_NAME=$(echo $GITHUB_REPOSITORY | sed 's/^.*\///')
TARGET_PATH="$GITHUB_WORKSPACE"
if [ -n "$DOCKER_REPO_APP_DIRECTORY" ]; then
    TARGET_PATH="${TARGET_PATH}/${DOCKER_REPO_APP_DIRECTORY}"
fi


mkdir -p "${GITHUB_ACTION_PATH}/operations/deployment/$1/app/${GITHUB_REPO_NAME}"

if [ $(find "$TARGET_PATH/." -iname "*"  -not -name "."| wc -l) -gt 0 ]; then 
  echo "Copying files from $TARGET_PATH to ops repo's Ansible $1 deployment (${GITHUB_ACTION_PATH}/operations/deployment/$1/app/${GITHUB_REPO_NAME})"
  cp -rf "$TARGET_PATH"/. "${GITHUB_ACTION_PATH}/operations/deployment/$1/app/${GITHUB_REPO_NAME}/"
else 
  echo "Nothing to copy from repo"
fi
echo "Done with generate_app_repo.sh"