#!/bin/bash
# This script will remove the state-file if set for deletion.
# If the bucket is empty and set for destruction, will delete it. 

echo ""

bucket="$TF_STATE_BUCKET"
commons_module="eks"

function generate_tf_state_file_name () {
  if [ -n "$TF_STATE_FILE_NAME" ]; then
    filename="$TF_STATE_FILE_NAME"
  else
    filename="tf-state-$1"
  fi

  if [ -n "$TF_STATE_FILE_NAME_APPEND" ]; then
    filename="${filename}-${TF_STATE_FILE_NAME_APPEND}"
  fi
  echo $filename
}

function check_aws_bucket_for_file() {
  bucket="$1"
  file_key="$2"
  aws s3 ls "s3://$bucket/$file_key" --summarize &>/dev/null
  return $?
}

tf_state_file=$(generate_tf_state_file_name $commons_module)

if [[ "$BITOPS_TERRAFORM_COMMAND" == "destroy" ]]; then
  if check_aws_bucket_for_file $bucket "$tf_state_file"; then
    aws s3 rm "s3://$bucket/$tf_state_file"
  fi
  # Check if the bucket is empty and delete it if true
  if [[ "$TF_STATE_BUCKET_DESTROY" == "true" ]]; then 
    if aws s3 ls "s3://$bucket" | wc -l | grep -q '^0$'; then
      echo "Destroying TF State S3 bucket --> $bucket"
      aws s3 rb "s3://$bucket"
    fi
  fi
fi