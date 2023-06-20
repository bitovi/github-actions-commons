#!/bin/bash

set -e
echo ""
echo "###########################################################################"
echo "BitOps --> Running Helm charts installation checks ...."
echo "###########################################################################"
echo ""
# Making sure everything in helm plugin is executable
for file in $(find /opt/bitops/scripts/installed_plugins/helm -iname "*.sh"); do chmod 755 $file; done