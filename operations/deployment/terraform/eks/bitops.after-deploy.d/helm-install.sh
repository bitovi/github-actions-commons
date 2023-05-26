#!/bin/bash

set -e
echo ""
echo "###########################################################################"
echo "BitOps --> Running Helm charts installation checks ...."
echo "###########################################################################"
echo ""

function remove_extension() {
  local filename="${1##*/}"     # Extract the file name from the provided path
  echo "${filename%.*}"         # Remove the file extension
}

#function install_charts (){
#  source_folder="$1"
#  if [ -d $source_folder ]; then
###    # Move files from source folder to destination folder
###    for chart in $($source_folder" -maxdepth 1 -type f -path ); do
###      echo "Installing chart: $chart"
###      echo "helm install $(remove_extension $chart) $source_folder/$chart"
###    done
###    for chart in $(find "$source_folder" -type d -maxdepth 1); do
###      echo "Installing chart: $chart"
###      echo "helm install $chart $source_folder/$chart"
###    done
###    #find "$source_folder" -maxdepth 1 -type f -path "$source_folder/*.tgz" | while read file; do
###    #  echo "Installing $file"
###    #  helm install $(remove_extension "$file") $source_folder/$file
###    #done
###    ## Move remaining folders (if they exist) and exclude the . folder
###    #find "$source_folder" -maxdepth 1 -type d -not -name "." -path "$source_folder/*" | while read folder; do
###    #  echo "Installing $folder"
###    #  helm install $folder $source_folder/$folder
###    #done
#  fi
#}

aws eks update-kubeconfig --name eks-cluster
helm update aws-auth ${BITOPS_ENVROOT}/terraform/eks/helm-charts/action-charts/aws-auth
#install_charts "${BITOPS_ENVROOT}/terraform/eks/helm-charts/deployment-charts/"
#install_charts "${BITOPS_ENVROOT}/terraform/eks/helm-charts/action-charts/"