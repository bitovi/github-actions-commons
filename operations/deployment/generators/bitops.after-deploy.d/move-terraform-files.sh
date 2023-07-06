#!/bin/bash

set -e
echo ""
echo "###########################################################################"
echo "BitOps --> Moving Terraform generated files to be excecuted by Terraform..."
echo "###########################################################################"
echo ""

## TODO: Rewrite this to a function

rm "${BITOPS_ENVROOT}/generators/generator.tf"
rm "${BITOPS_ENVROOT}/generators/variables.tf"
rm "${BITOPS_ENVROOT}/generators/terraform.tfvars"

#if [ $(find "$BITOPS_ENVROOT/generators/." -iname "bitovi_*postgres.tf" | wc -l) -gt 0 ]; then 
  #mv "${BITOPS_ENVROOT}"/generators/bitovi_*postgres.tf "${BITOPS_ENVROOT}"/terraform/aws/rds/.
  cp "${BITOPS_ENVROOT}"/generators/modules/aws/aws_default* "${BITOPS_ENVROOT}"/terraform/aws/rds/.
#fi
#if [ $(find "$BITOPS_ENVROOT/generators/." -iname "bitovi_aws_efs.tf" | wc -l) -gt 0 ]; then 
  #mv "${BITOPS_ENVROOT}"/generators/bitovi_aws_efs.tf "${BITOPS_ENVROOT}"/terraform/aws/efs/.
  #cp "${BITOPS_ENVROOT}"/generators/modules/aws/aws_default* "${BITOPS_ENVROOT}"/terraform/aws/efs/.
#fi
#if [ $(find "$BITOPS_ENVROOT/generators/." -iname "bitovi_aws_eks*.tf" | wc -l) -gt 0 ]; then 
  #mv "${BITOPS_ENVROOT}"/generators/bitovi_aws_eks*.tf "${BITOPS_ENVROOT}"/terraform/aws/eks/.
  cp "${BITOPS_ENVROOT}"/generators/modules/aws/aws_default* "${BITOPS_ENVROOT}"/terraform/aws/eks/.
#fi
if [ $(find "$BITOPS_ENVROOT/generators/." -iname "bitovi_*.tf" | wc -l) -gt 0 ]; then 
  mv "${BITOPS_ENVROOT}"/generators/bitovi_*.tf "${BITOPS_ENVROOT}"/terraform/aws/ec2/.
  mv "${BITOPS_ENVROOT}"/generators/modules/aws/aws_default* "${BITOPS_ENVROOT}"/terraform/aws/ec2/.
fi 

find "${BITOPS_ENVROOT}/terraform/aws" -maxdepth 1 -type d -not -name "."  -path "${BITOPS_ENVROOT}/terraform/aws/*" | while read terraform_folder; do
  cat "${BITOPS_ENVROOT}/generators/modules/aws/aws_variables.tf" >> $terraform_folder/variables.tf
  cat "${BITOPS_ENVROOT}/generators/modules/aws/aws_terraform.tfvars" >> $terraform_folder/terraform.tfvars
done

rm -rf "${BITOPS_ENVROOT}/generators"
cp -r "${BITOPS_ENVROOT}" /opt/bitops_deployment/generated_code