#!/bin/bash

set -e
echo ""
echo "###########################################################################"
echo "BitOps --> Moving Terraform generated files to be excecuted by Terraform..."
echo "###########################################################################"
echo ""

echo "Init"
ls -lah ${BITOPS_ENVROOT}/generators/
rm "${BITOPS_ENVROOT}/generators/generator.tf"
rm "${BITOPS_ENVROOT}/generators/variables.tf"
rm "${BITOPS_ENVROOT}/generators/terraform.tfvars"

# THIS FIND IT'S NOT WORKING
if [ $(find "$BITOPS_ENVROOT/generators/." -iname "bitovi_*postgres.tf" | wc -l) -gt 0 ]; then 
  mv "${BITOPS_ENVROOT}"/generators/bitovi_*postgres.tf "${BITOPS_ENVROOT}"/terraform/rds/.
  cp "${BITOPS_ENVROOT}"/generators/bitovi_aws_default* "${BITOPS_ENVROOT}"/terraform/rds/.
  echo "RDS"
  ls -lah ${BITOPS_ENVROOT}/generators/
fi
if [ $(find "$BITOPS_ENVROOT/generators/." -iname "bitovi_*.tf" | wc -l) -gt 0 ]; then 
  echo "EC2"
  ls -lah ${BITOPS_ENVROOT}/generators/
  mv "${BITOPS_ENVROOT}"/generators/bitovi_*.tf "${BITOPS_ENVROOT}"/terraform/ec2/.
fi 

echo "Final"

ls -lah ${BITOPS_ENVROOT}/generators/
rm -rf "${BITOPS_ENVROOT}/generators"
cp -r "${BITOPS_ENVROOT}" /opt/bitops_deployment/generated_code

cat "${BITOPS_ENVROOT}"/bitops.config.yaml
ls -lah "${BITOPS_ENVROOT}"