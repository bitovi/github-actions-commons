#!/bin/bash

set -e

echo "In generate_provider_azure.sh"

echo "
terraform {
  required_providers {
    azurerm = {
      source  = \"hashicorp/azurerm\"
      version = \"~> 2.75\"
    }
    random = {
      source  = \"hashicorp/random\"
      version = \">= 2.2\"
    }
  }

  backend \"azurerm\" {
    resource_group_name  = \"${AZURE_RESOURCE_GROUP}\"
    storage_account_name = \"${TF_STATE_STORAGE_ACCOUNT}\"
    container_name       = \"${TF_STATE_CONTAINER}\"
    key                  = \"tf-state\"
  }
}

provider \"azurerm\" {
  features {}
  subscription_id = \"${AZURE_SUBSCRIPTION_ID}\"
  tenant_id       = \"${AZURE_TENANT_ID}\"
  client_id       = \"${AZURE_CLIENT_ID}\"
  client_secret   = \"${AZURE_CLIENT_SECRET}\"

  default_tags {
    tags = merge(
      local.azure_tags,
      var.azure_additional_tags
    )
  }
}
" > "${GITHUB_ACTION_PATH}/operations/deployment/terraform/bitovi_provider.tf"

echo "Done with generate_provider_azure.sh"