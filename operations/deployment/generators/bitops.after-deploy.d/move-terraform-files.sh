#!/bin/bash

set -e


echo "BitOps Ansible before script: Merge Terraform Enviornment Variables..."


ls -lah "${BITOPS_ENVROOT}/generators"
rm "${BITOPS_ENVROOT}/generators/generator.tf"
rm "${BITOPS_ENVROOT}/generators/variables.tf"
rm "${BITOPS_ENVROOT}/generators/variables.tfvars"
mv "${BITOPS_ENVROOT}/generators/*.tf" "${BITOPS_ENVROOT}/terraform/."
ls -lah "${BITOPS_ENVROOT}/terraform"
