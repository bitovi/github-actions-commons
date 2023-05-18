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
  cp -rf "$TARGET_PATH"/* "${GITHUB_ACTION_PATH}/operations/deployment/$1/app/${GITHUB_REPO_NAME}/"
else 
  echo "Nothing to copy from repo"
fi
echo "Done with generate_app_repo.sh"

echo "1 $1"
echo "GITHUB_ACTION_PATH $GITHUB_ACTION_PATH"
echo "GITHUB_REPO_NAME $GITHUB_REPO_NAME"
echo "TARGET_PATH $TARGET_PATH"
echo "GITHUB_WORKSPACE $GITHUB_WORKSPACE"
echo "DOCKER_REPO_APP_DIRECTORY $DOCKER_REPO_APP_DIRECTORY"

#echo "In generate_app_repo.sh"
#GITHUB_REPO_NAME=$(echo $GITHUB_REPOSITORY | sed 's/^.*\///')
#
#echo "Copying files from GITHUB_WORKSPACE ($GITHUB_WORKSPACE) to ops repo's Ansible deployment (${GITHUB_ACTION_PATH}/operations/deployment/ansible/app/${GITHUB_REPO_NAME})"
#mkdir -p "${GITHUB_ACTION_PATH}/operations/deployment/ansible/app/${GITHUB_REPO_NAME}"
#
#TARGET_PATH="$GITHUB_WORKSPACE"
#if [ -n "$APP_DIRECTORY" ]; then
#    echo "APP_DIRECTORY: $APP_DIRECTORY"
#    TARGET_PATH="${TARGET_PATH}/${APP_DIRECTORY}"
#fi
#
#cp -rf "$TARGET_PATH"/* "${GITHUB_ACTION_PATH}/operations/deployment/ansible/app/${GITHUB_REPO_NAME}/"
#
#if [ -s "$TARGET_PATH/$REPO_ENV" ]; then
#  echo "Copying checked in env file from repo to Ansible deployment path"
#  cp "$TARGET_PATH/$REPO_ENV" "${GITHUB_ACTION_PATH}/operations/deployment/ansible/repo.env"
#else
#  echo "Checked in env file from repo is empty or couldn't be found"
#fi