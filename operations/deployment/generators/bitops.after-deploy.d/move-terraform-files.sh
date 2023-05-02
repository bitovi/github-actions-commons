#!/bin/bash

set -e

echo "BitOps --> Moving Terraform generated files to be excecuted by Terraform..."

rm "${BITOPS_ENVROOT}/generators/generator.tf"
rm "${BITOPS_ENVROOT}/generators/variables.tf"
rm "${BITOPS_ENVROOT}/generators/terraform.tfvars"
mv "${BITOPS_ENVROOT}"/generators/bitovi_*postgres.tf "${BITOPS_ENVROOT}"/terraform/rds/.
cp "${BITOPS_ENVROOT}"/generators/bitovi_default* "${BITOPS_ENVROOT}"/terraform/rds/.
mv "${BITOPS_ENVROOT}"/generators/bitovi_*.tf "${BITOPS_ENVROOT}"/terraform/ec2/.
rm -rf "${BITOPS_ENVROOT}/generators"
cp -r "${BITOPS_ENVROOT}" /opt/bitops_deployment/generated_code