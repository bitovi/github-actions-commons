#!/bin/bash
echo "BitOps Ansible before script: Waiting for inventory hosts..."
cat ${BITOPS_ENVROOT}/terraform/inventory.yaml
python $BITOPS_TEMPDIR/_scripts/ansible/wait-for-inventory-hosts.py