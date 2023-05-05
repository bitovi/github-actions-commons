#!/bin/bash
echo ""

echo "BITOPS_TERRAFORM_COMMAND $BITOPS_TERRAFORM_COMMAND"
echo "TF_STATE_BUCKET_DESTROY $TF_STATE_BUCKET_DESTROY"
if [ $BITOPS_TERRAFORM_COMMAND == "destroy" ] && [ $TF_STATE_BUCKET_DESTROY = "true" ]; then 
  echo "Destroying TF State S3 bucket --> $TF_STATE_BUCKET"
  aws s3 rb s3://$TF_STATE_BUCKET --force
else
  echo "TF State bucket not destroyed --> $TF_STATE_BUCKET"
fi
