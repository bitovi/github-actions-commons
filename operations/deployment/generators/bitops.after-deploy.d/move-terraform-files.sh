#!/bin/bash

set -e

echo "BitOps --> Moving Terraform generated files to be excecuted by Terraform..."

rm "${BITOPS_ENVROOT}/generators/generator.tf"
rm "${BITOPS_ENVROOT}/generators/variables.tf"
rm "${BITOPS_ENVROOT}/generators/terraform.tfvars"
if [ $(find "${BITOPS_ENVROOT}"/generators/. -iname bitovi_*postgres.tf | wc -l) -gt 0 ]; then 
  mv "${BITOPS_ENVROOT}"/generators/bitovi_*postgres.tf "${BITOPS_ENVROOT}"/terraform/rds/.
  cp "${BITOPS_ENVROOT}"/generators/bitovi_aws_default* "${BITOPS_ENVROOT}"/terraform/rds/.
fi
if [ $(find "${BITOPS_ENVROOT}"/generators/. -iname bitovi_*.tf | wc -l) -gt 0 ]; then 
  mv "${BITOPS_ENVROOT}"/generators/bitovi_*.tf "${BITOPS_ENVROOT}"/terraform/ec2/.
fi 
rm -rf "${BITOPS_ENVROOT}/generators"
cp -r "${BITOPS_ENVROOT}" /opt/bitops_deployment/generated_code

cat "${BITOPS_ENVROOT}"/bitops.config.yaml
ls -lah "${BITOPS_ENVROOT}"