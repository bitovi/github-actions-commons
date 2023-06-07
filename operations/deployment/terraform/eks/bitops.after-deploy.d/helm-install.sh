#!/bin/bash

set -e
echo ""
echo "###########################################################################"
echo "BitOps --> Running Helm charts installation checks ...."
echo "###########################################################################"
echo ""

helm_command="helm upgrade --install --create-namespace -n kube-system"

function remove_extension() {
  local filename="${1##*/}"     # Extract the file name from the provided path
  echo "${filename%.*}"         # Remove the file extension
}

function install_charts (){
  source_folder="$1"
  echo "Running through $source_folder"
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
  #install_charts "${BITOPS_ENVROOT}/terraform/eks/helm-charts/deployment-charts"
  #ls -l "${BITOPS_ENVROOT}/terraform/eks/helm-charts/deployment-charts"
  #install_charts "${BITOPS_ENVROOT}/terraform/eks/helm-charts/action-charts"
  #ls -l "${BITOPS_ENVROOT}/terraform/eks/helm-charts/action-charts"

  ## DEBUG
  echo "kubectl describe after charts installation"
  #kubectl describe configmap -n kube-system aws-auth
  curl -O https://s3.us-west-2.amazonaws.com/amazon-eks/cloudformation/2020-10-29/aws-auth-cm.yaml
  sed -i.bak -e 's|<ARN of instance role (not instance profile)>|arn:aws:iam::755521597925:role/AWSReservedSSO_AdministratorAccess_402f22a297379e03|' aws-auth-cm.yaml
  kubectl apply -f aws-auth-cm.yaml
  kubectl describe configmap -n kube-system aws-auth
  # echo "kubectl get configmaps --all-namespaces"
  # kubectl get configmaps --all-namespaces
  # echo "kubectl get namespaces"
  # kubectl get namespaces
  # echo "kubectl get deployments --all-namespaces"
  # kubectl get deployments --all-namespaces
  # echo "kubectl get configmaps --all-namespaces"
  # kubectl get configmap aws-auth -n default -o yaml
  # echo "AWS Suggestions"
  # echo "###############"
  # echo "kubectl describe -n default configmap/aws-auth"
  # kubectl describe -n default configmap/aws-auth
  echo "kubectl get roles -A"
  kubectl get roles -A
  echo "kubectl get clusterroles"
  kubectl get clusterroles
  echo "kubectl get rolebindings -A"
  kubectl get rolebindings -A
  echo "kubectl get clusterrolebindings"
  kubectl get clusterrolebindings
fi
