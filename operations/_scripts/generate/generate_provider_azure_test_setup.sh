#!/bin/bash
# Here's the shell script with example values for the environment variables
# These example values won't work with a real Azure subscription, but they can be used to test the script itself. 
# Save this script as `set_azure_env_vars.sh` and run `source set_azure_env_vars.sh` in your terminal to set the 
# environment variables before executing Terraform commands. 
# Make sure to replace the example values with your actual Azure subscription and backend configuration details 
# when you're ready to run real tests or deployments.

# set test directory - modify if necessary
export GITHUB_ACTION_PATH=~/Bitovi/github/github-actions-commons

# Set environment variables for Azure authentication
export AZURE_SUBSCRIPTION_ID="00000000-1111-2222-3333-444444444444"
export AZURE_TENANT_ID="11111111-2222-3333-4444-555555555555"
export AZURE_CLIENT_ID="22222222-3333-4444-5555-666666666666"
export AZURE_CLIENT_SECRET="aBcDeFgHiJkLmNoPqRsTuVwXyZ1234567890"

# Set environment variables for Azure backend configuration
export AZURE_RESOURCE_GROUP="my-resource-group"
export TF_STATE_STORAGE_ACCOUNT="mytfstatestorage"
export TF_STATE_CONTAINER="terraform-state"

# Print the environment variables to verify
echo "Github Action Path: $GITHUB_ACTION_PATH"
echo "Azure Subscription ID: $AZURE_SUBSCRIPTION_ID"
echo "Azure Tenant ID: $AZURE_TENANT_ID"
echo "Azure Client ID: $AZURE_CLIENT_ID"
echo "Azure Client Secret: [REDACTED]"
echo "Azure Resource Group: $AZURE_RESOURCE_GROUP"
echo "Terraform State Storage Account: $TF_STATE_STORAGE_ACCOUNT"
echo "Terraform State Container: $TF_STATE_CONTAINER"
