#!/bin/bash

set -e

echo "BitOps --> Moving Terraform generated files to be excecuted by Terraform..."

rm "${BITOPS_ENVROOT}/generators/generator.tf"
rm "${BITOPS_ENVROOT}/generators/variables.tf"
rm "${BITOPS_ENVROOT}/generators/terraform.tfvars"
mv "${BITOPS_ENVROOT}"/generators/bitovi_*.tf "${BITOPS_ENVROOT}"/terraform/.
rm -rf "${BITOPS_ENVROOT}/generators"
cp -r "${BITOPS_ENVROOT}" /opt/bitops_deployment/generated_code