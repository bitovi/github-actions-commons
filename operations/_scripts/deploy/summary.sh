#!/bin/bash
# shellcheck disable=SC2086

### coming into this we have env vars:
# SUCCESS=${{ success() }}
# URL_OUTPUT=${{ steps.deploy.outputs.vm_url }}
# BITOPS_CODE_ONLY
# BITOPS_CODE_STORE
# TF_STACK_DESTROY
# TF_STATE_BUCKET_DESTROY

if [[ $SUCCESS == 'true' ]]; then 
  if [[ $URL_OUTPUT != '' ]]; then
    #Print result created
    result_string="
    ## VM Created! :rocket:
    $URL_OUTPUT"
  elif [[ $BITOPS_CODE_ONLY == 'true' && $BITOPS_CODE_STORE == 'true' ]]; then
    #Print code generated and archived
    result_string="## BitOps Code generated. :tada: 
    Download the code artifact. Will be there for 5 days.
    Keep in mind that for creation, EFS should be created before EC2.
    While destroying, EC2 should be destroyed before EFS. (Due to resources being in use).
    You can change that in the bitops.config.yaml file, or regenerate the code with destroy set."
  elif [[ $BITOPS_CODE_ONLY == 'true' && $BITOPS_CODE_STORE != 'true' ]]; then
    #Print code generated not archived
    result_string="## BitOps Code generated. :tada:"
  elif [[ $TF_STACK_DESTROY != 'true' && $BITOPS_CODE_ONLY != 'true' ]]; then
    #Print result deploy finished but no URL
    result_string="## Deploy finished! But no URL found. :thinking:
    If expecting a URL, please check the logs for possible  errors.
    If you consider this is a bug in the Github Action, please submit an issue to our repo."
  elif [[ $TF_STACK_DESTROY == 'true' && $TF_STATE_BUCKET_DESTROY != 'true' ]]; then
    result_string="## VM Destroyed! :boom:
    Infrastructure should be gone now!"
  elif [[ $TF_STACK_DESTROY == 'true' && $TF_STATE_BUCKET_DESTROY == 'true' ]]; then
    result_string="## VM Destroyed! :boom:
    Buckets and infrastructure should be gone now!"
  fi
else
  # Print error result
  result_string="## Workflow failed to run :fire:
  Please check the logs for possible errors.
  If you consider this is a bug in the Github Action, please submit an issue to our repo."
fi

echo "$result_string" >> $GITHUB_OUTPUT
