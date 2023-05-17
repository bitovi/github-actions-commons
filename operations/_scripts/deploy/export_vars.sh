#!/bin/bash
# Export variables to GHA

set -ex 
echo "::group::Passing vars to GH"

echo "GAP"
ls -lah "$GITHUB_ACTION_PATH"
echo "GAP/ops/"
ls -lah "$GITHUB_ACTION_PATH/operations/"
echo "GAP/ops/"
ls -lah "$GITHUB_ACTION_PATH/operations/deployment"
ls -lah "$GITHUB_ACTION_PATH/operations/deployment/ansible"
ls -lah "$GITHUB_ACTION_PATH/operations/deployment/env-files"
ls -lah "$GITHUB_ACTION_PATH/operations/deployment/generators"
ls -lah "$GITHUB_ACTION_PATH/operations/deployment/terraform"
ls -lah "$GITHUB_ACTION_PATH/operations/deployment/terraform/ec2"


find "bo-out.env" -maxdepth 1 -type f -path "$GITHUB_ACTION_PATH/*" 

echo "Last env's"
env
echo "That's it env's"


if [ "$TF_STACK_DESTROY" != "true" ]; then
  BO_OUT="$GITHUB_ACTION_PATH/operations/bo-out.env"
  
  echo "Check for $BO_OUT"
  if [ -s $BO_OUT ]; then
    echo "Outputting bo-out.env to GITHUB_OUTPUT"
    cat $BO_OUT >> $GITHUB_OUTPUT
  else
    echo "BO_OUT is not a file or it's empty"
  fi
else
  echo "Destroy process executed. No variables to be exported."
fi
echo "::endgroup::"