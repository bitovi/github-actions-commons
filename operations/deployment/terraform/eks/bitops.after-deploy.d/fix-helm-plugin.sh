#!/bin/bash

# Making sure everything in helm plugin is executable
for file in $(find /opt/bitops/scripts/installed_plugins/helm -iname "*.sh"); do chmod 755 $file; done