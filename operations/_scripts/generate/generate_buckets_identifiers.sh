#!/bin/bash

set -e

GITHUB_IDENTIFIER="$($GITHUB_ACTION_PATH/operations/_scripts/generate/generate_identifier.sh)"

case $1 in 
  tf)
      # Generate TF_STATE_BUCKET ID if empty 
      if [ -z "${TF_STATE_BUCKET}" ]; then
        #  Add trailing id depending on name length - See AWS S3 bucket naming rules
        if [[ ${#GITHUB_IDENTIFIER} < 55 ]]; then
          TF_STATE_BUCKET="${GITHUB_IDENTIFIER}-tf-state"
        else
          TF_STATE_BUCKET="${GITHUB_IDENTIFIER}-tf"
        fi
      fi
      echo "$TF_STATE_BUCKET"

  ;;
  lb)
      # Generate AWS_ELB_ACCESS_LOG_BUCKET_NAME ID - # Not in use anymore
      #  Add trailing id depending on name length - See AWS S3 bucket naming rules
      if [[ ${#GITHUB_IDENTIFIER} < 59 ]]; then
        AWS_ELB_ACCESS_LOG_BUCKET_NAME="${GITHUB_IDENTIFIER}-logs"
      else
        AWS_ELB_ACCESS_LOG_BUCKET_NAME="${GITHUB_IDENTIFIER}-lg"
      fi
      echo "$AWS_ELB_ACCESS_LOG_BUCKET_NAME"
  ;;
esac