#!/bin/bash
# Export variables to Ansible

BITOPS_EC2_PUBLIC_IP="$(cat /opt/bitops_deployment/bo-out.env| grep instance_public_ip | awk -F"=" '{print $2}')"
sed -i "s/BITOPS_EC2_PUBLIC_IP/$(echo $BITOPS_EC2_PUBLIC_IP)/" ${BITOPS_ENVROOT}/terraform/ec2/inventory.yaml