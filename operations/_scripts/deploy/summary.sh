#!/bin/bash
# shellcheck disable=SC2086

### coming into this we have env vars:
# SUCCESS=${{ job.status }} # success, cancelled, failure
# URL_OUTPUT=${{ steps.deploy.outputs.vm_url }}
# BITOPS_CODE_ONLY
# BITOPS_CODE_STORE
# TF_STACK_DESTROY
# TF_STATE_BUCKET_DESTROY

# Create an error code mechanism so we don't have to check the actual static text,
# just which case we fell into

# 0 - success
# 1 - failure
# 2 - failure, no URL # invalid case
# 3 - failure, no URL, no code generated # invalid case
# 4 - success, no URL
# 5 - success, code generated, not archived
# 6 - success, code generated, archived
# 7 - success, code generated, archived, but no URL found # invalid case
# 8 - success, destroy buckets and infrastructure
# 9 - success, destroy infrastructure
# 10 - cancelled

SUMMARY_CODE=0

if [[ $SUCCESS == 'success' ]]; then
  if [[ $URL_OUTPUT != '' ]]; then
    result_string="## Deploy Complete! :rocket:
    $URL_OUTPUT"

  elif [[ $BITOPS_CODE_ONLY == 'true' ]]; then
    if [[ $BITOPS_CODE_STORE == 'true' ]]; then
      SUMMARY_CODE=6
      result_string="## BitOps Code generated. :tada: 
      Download the code artifact. Will be there for 5 days.
      Keep in mind that for creation, EFS should be created before EC2.
      While destroying, EC2 should be destroyed before EFS. (Due to resources being in use).
      You can change that in the bitops.config.yaml file, or regenerate the code with destroy set."
    else
      SUMMARY_CODE=5
      result_string="## BitOps Code generated. :tada:"
    fi

  elif [[ $TF_STACK_DESTROY == 'true' ]]; then
    if [[ $TF_STATE_BUCKET_DESTROY != 'true' ]]; then
      SUMMARY_CODE=9
      result_string="## VM Destroyed! :boom:
      Infrastructure should be gone now!"
    else
      SUMMARY_CODE=8
      result_string="## VM Destroyed! :boom:
      Buckets and infrastructure should be gone now!"
    fi

  elif [[ $TF_STACK_DESTROY != 'true' && $BITOPS_CODE_ONLY != 'true' ]]; then
    SUMMARY_CODE=4
    result_string="## Deploy finished! But no URL found. :thinking:
    If expecting a URL, please check the logs for possible errors.
    If you consider this is a bug in the Github Action, please submit an issue to our repo."
  fi
elif [[ $SUCCESS == 'cancelled' ]]; then
  SUMMARY_CODE=10
  result_string="## Workflow cancelled :warning:"

else
  SUMMARY_CODE=1
  result_string="## Workflow failed to run :fire:
  Please check the logs for possible errors.
  If you consider this is a bug in the Github Action, please submit an issue to our repo."
fi

echo "$result_string" >> $GITHUB_STEP_SUMMARY
echo "SUMMARY_CODE=$SUMMARY_CODE" >> $GITHUB_OUTPUT
