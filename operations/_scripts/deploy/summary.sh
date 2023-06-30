#!/bin/bash
# shellcheck disable=SC2086

### coming into this we have env vars:
# SUCCESS=${{ success() }}
# URL_OUTPUT=${{ steps.deploy.outputs.vm_url }}
# BITOPS_CODE_ONLY
# BITOPS_CODE_STORE
# TF_STACK_DESTROY
# TF_STATE_BUCKET_DESTROY



if [[ $SUCCESS == 'true' && $URL_OUTPUT != '' ]]; then
  #Print result created
  echo "## VM Created! :rocket:" >> $GITHUB_STEP_SUMMARY
  echo "$URL_OUTPUT" >> $GITHUB_STEP_SUMMARY
elif [[ $SUCCESS == 'true' && $URL_OUTPUT == '' && $BITOPS_CODE_ONLY == 'true' && $BITOPS_CODE_STORE == 'true' ]]; then
  #Print code generated and archived
  echo "## BitOps Code generated. :tada: " >> $GITHUB_STEP_SUMMARY
  echo "Download the code artifact. Will be there for 5 days." >> $GITHUB_STEP_SUMMARY
  echo "Keep in mind that for creation, EFS should be created before EC2."
  echo "While destroying, EC2 should be destroyed before EFS. (Due to resources being in use)."
  echo "You can change that in the bitops.config.yaml file, or regenerate the code with destroy set."
elif [[ $SUCCESS == 'true' && $URL_OUTPUT == '' && $BITOPS_CODE_ONLY == 'true' && $BITOPS_CODE_STORE != 'true' ]]; then
  #Print code generated not archived
  echo "## BitOps Code generated. :tada: " >> $GITHUB_STEP_SUMMARY
elif [[ $SUCCESS == 'true' && $URL_OUTPUT == '' && $TF_STACK_DESTROY != 'true' && $BITOPS_CODE_ONLY != 'true' ]]; then
  #Print result deploy finished but no URL
  echo "## Deploy finished! But no URL found. :thinking: " >> $GITHUB_STEP_SUMMARY
  echo "If expecting an URL, please check the logs for possible  errors." >> $GITHUB_STEP_SUMMARY
  echo "If you consider this is a bug in the Github Action, please submit an issue to our repo." >> $GITHUB_STEP_SUMMARY
elif [[ $SUCCESS == 'true' && $URL_OUTPUT == '' && $TF_STACK_DESTROY == 'true' && $TF_STATE_BUCKET_DESTROY != 'true' ]]; then
  echo "## VM Destroyed! :boom:" >> $GITHUB_STEP_SUMMARY
  echo "Infrastructure should be gone now!" >> $GITHUB_STEP_SUMMARY
elif [[ $SUCCESS == 'true' && $URL_OUTPUT == '' && $TF_STACK_DESTROY == 'true' && $TF_STATE_BUCKET_DESTROY == 'true' ]]; then
  echo "## VM Destroyed! :boom:" >> $GITHUB_STEP_SUMMARY
  echo "Buckets and infrastructure should be gone now!" >> $GITHUB_STEP_SUMMARY
elif [[ $SUCCESS != 'true' ]]; then
  # Print error result
  echo "## Workflow failed to run :fire:" >> $GITHUB_STEP_SUMMARY
  echo "Please check the logs for possible errors." >> $GITHUB_STEP_SUMMARY
  echo "If you consider this is a bug in the Github Action, please submit an issue to our repo." >> $GITHUB_STEP_SUMMARY
fi



