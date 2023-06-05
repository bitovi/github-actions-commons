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
        echo "Installing chart: $chart - FILE"
        $helm_command $(remove_extension $chart) "$source_folder/$chart"
      done
    fi
    for chart in $(find ${source_folder} -maxdepth 1 -type d -not -name $(basename $source_folder)); do
      chart=$(basename $chart)
      echo "Installing chart: $chart - DIR"
      $helm_command $chart "$source_folder/$chart"
    done
  fi
}

if [ "$BITOPS_TERRAFORM_COMMAND" != "destroy" ]; then
  aws eks update-kubeconfig --name eks-cluster
  install_charts "${BITOPS_ENVROOT}/terraform/eks/helm-charts/deployment-charts"
  install_charts "${BITOPS_ENVROOT}/terraform/eks/helm-charts/action-charts"
  echo "kubectl describe after charts installation"
  echo "kubectl get configmaps --all-namespaces"
  kubectl get configmaps --all-namespaces
  echo "kubectl get namespaces"
  kubectl get namespaces
  echo "kubectl get helmcharts --all-namespaces"
  kubectl get helmcharts --all-namespaces
  echo "kubectl get deployments --all-namespaces"
  kubectl get deployments --all-namespaces
fi