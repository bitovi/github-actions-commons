#!/bin/bash

echo ""
if [[ ${#TF_STATE_BUCKET} > 63 ]]; then
  echo "Bucket name exceeds name limit"
  exit 63
else
  echo "Creating TF_STATE_BUCKET: $TF_STATE_BUCKET"
  if [ "$AWS_DEFAULT_REGION" == "us-east-1" ]; then
    aws s3api create-bucket --bucket $TF_STATE_BUCKET --region $AWS_DEFAULT_REGION || true
  else
    aws s3api create-bucket --bucket $TF_STATE_BUCKET --region $AWS_DEFAULT_REGION --create-bucket-configuration LocationConstraint=$AWS_DEFAULT_REGION || true
  fi
  echo "File only needed to test bucket access. Shouldn't be here. Can be safely deleted" >> bitovi-github-actions-commons.statecheck.txt
  if ! [[ -z $(aws s3api put-object --bucket $TF_STATE_BUCKET --key bitovi-github-actions-commons.statecheck.txt --body ./bitovi-github-actions-commons.statecheck.txt 2>&1 >/dev/null ) ]]; then
    echo "Permission issue: Unable to write to the bucket."
    exit 63
  else
      if ! [[ $(aws s3 rm "s3://$TF_STATE_BUCKET/bitovi-github-actions-commons.statecheck.txt" 2>&1 >/dev/null ) ]]; then
            echo "Access to bucket confirmed. Can create and delete a tf-state file"
      fi
  fi
  rm bitovi-github-actions-commons.statecheck.txt
fi
