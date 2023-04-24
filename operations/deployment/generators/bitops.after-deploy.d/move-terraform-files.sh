#!/bin/bash

set -e

echo "BitOps --> Moving Terraform generated files to be excecuted by Terraform..."


ls -lah "${BITOPS_ENVROOT}/generators"
rm "${BITOPS_ENVROOT}/generators/generator.tf"
rm "${BITOPS_ENVROOT}/generators/variables.tf"
rm "${BITOPS_ENVROOT}/generators/terraform.tfvars"
mv "${BITOPS_ENVROOT}"/generators/*.tf "${BITOPS_ENVROOT}"/terraform/.
rm -rf "${BITOPS_ENVROOT}/generators"
ls -lah "${BITOPS_ENVROOT}/terraform"
echo "BITOPS_ENVROOT ${BITOPS_ENVROOT}"
ls -lah "${BITOPS_ENVROOT}"

zip --help