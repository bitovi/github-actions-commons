#!/bin/bash
# Export variables to GHA

echo "::group::Passing vars to GH"
if [ "$TF_STACK_DESTROY" != "true" ]; then
  BO_OUT="$GITHUB_ACTION_PATH/operations/bo-out.env"
  cat $BO_OUT
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


echo "GITHUB_ACTION_PATH $GITHUB_ACTION_PATH"
echo "GITHUB_REPO_NAME $GITHUB_REPO_NAME"
echo "TARGET_PATH $TARGET_PATH"
echo "GITHUB_WORKSPACE $GITHUB_WORKSPACE"
echo "DOCKER_REPO_APP_DIRECTORY $DOCKER_REPO_APP_DIRECTORY"

tree /home/runner/work
ls /home/runner/work
mkdir -p $GITHUB_WORKSPACE