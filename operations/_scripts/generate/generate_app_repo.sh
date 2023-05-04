#!/bin/bash

set -e

echo "In generate_app_repo.sh"
GITHUB_REPO_NAME=$(echo $GITHUB_REPOSITORY | sed 's/^.*\///')

echo "Copying files from GITHUB_WORKSPACE ($GITHUB_WORKSPACE) to ops repo's Ansible $1 deployment (${GITHUB_ACTION_PATH}/operations/deployment/$1/app/${GITHUB_REPO_NAME})"
mkdir -p "${GITHUB_ACTION_PATH}/operations/deployment/$1/app/${GITHUB_REPO_NAME}"

TARGET_PATH="$GITHUB_WORKSPACE"
if [ -n "$DOCKER_REPO_APP_DIRECTORY" ]; then
    echo "DOCKER_REPO_APP_DIRECTORY: $DOCKER_REPO_APP_DIRECTORY"
    TARGET_PATH="${TARGET_PATH}/${DOCKER_REPO_APP_DIRECTORY}"
fi

if [ $(find "$TARGET_PATH/." -iname "*" | wc -l) -gt 0 ]; then 
  echo "Got in this find"
  find "$TARGET_PATH/." -iname "*"
  cp -rf "$TARGET_PATH"/* "${GITHUB_ACTION_PATH}/operations/deployment/$1/app/${GITHUB_REPO_NAME}/"
  echo "Copied files"
fi
echo "Done with generate_app_repo.sh"