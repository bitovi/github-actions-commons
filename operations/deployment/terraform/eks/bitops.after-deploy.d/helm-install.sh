#!/bin/bash

set -e
echo ""
echo "###########################################################################"
echo "BitOps --> Running Helm charts installation checks ...."
echo "###########################################################################"
echo ""

helm_command="helm upgrade --install --create-namespace "

function remove_extension() {
  local filename="${1##*/}"     # Extract the file name from the provided path
  echo "${filename%.*}"         # Remove the file extension
}

function install_charts (){
  source_folder="$1"
  if [ -d $source_folder ]; then
    # Move files from source folder to destination folder
    if [ $(find ${source_folder} -maxdepth 1 -type f -iname "*.tgz" | wc -l) -gt 0 ]; then
      for chart in $(find ${source_folder} -maxdepth 1 -type f -iname "*.tgz"); do
        chart=$(basename $chart)
        echo "Installing chart: $chart"
        echo "$helm_command $(remove_extension $chart) $source_folder/$chart"
      done
    fi
    for chart in $(find ${source_folder} -maxdepth 1 -type d); do
      chart=$(basename $chart)
      echo "Installing chart: $chart"
      echo "$helm_command $chart $source_folder/$chart"
    done
  fi
}

aws eks update-kubeconfig --name eks-cluster
helm upgrade --install --create-namespace aws-auth ${BITOPS_ENVROOT}/terraform/eks/helm-charts/action-charts/aws-auth
install_charts "${BITOPS_ENVROOT}/terraform/eks/helm-charts/deployment-charts"
install_charts "${BITOPS_ENVROOT}/terraform/eks/helm-charts/action-charts"