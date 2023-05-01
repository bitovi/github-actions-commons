#!/bin/bash
# Export variables to Ansible

export BITOPS_EC2_PUBLIC_IP="$(cat /opt/bitops_deployment/bo-out.env| grep instance_public_ip | awk -F"=" '{print $2}')"
export BITOPS_EC2_PUBLIC_URL="$(cat /opt/bitops_deployment/bo-out.env| grep instance_public_dns | awk -F"=" '{print $2}')"
sed -i "s/BITOPS_EC2_PUBLIC_IP/$(echo $BITOPS_EC2_PUBLIC_IP)/" ${BITOPS_ENVROOT}/terraform/inventory.yaml