#!/bin/bash
# shellcheck disable=SC2086

### coming into this we have env vars:
# SUCCESS=${{ job.status }} # success, cancelled, failure
# URL_OUTPUT=${{ steps.deploy.outputs.vm_url }}
# EC2_URL_OUTPUT=${{ steps.deploy.outputs.instance_endpoint }}
# BITOPS_CODE_ONLY
# BITOPS_CODE_STORE
# TF_STACK_DESTROY
# TF_STATE_BUCKET_DESTROY
# AWS_EC2_PORT_LIST
# AWS_ELB_LISTEN_PORT
# ECR_REPO_ARN
# ECR_REPO_ID
# ECR_REPO_URL

# Create an error code mechanism so we don't have to check the actual static text,
# just which case we fell into

# 0 - success
# 1 - failure
# 2 - failure, no URL # invalid case
# 3 - failure, no URL, no code generated # invalid case
# 4 - success, no URL
# 5 - success, code generated, not archived
# 6 - success, code generated, archived
# 7 - success, code generated, archived, but no URL found # invalid case
# 8 - success, destroy buckets and infrastructure
# 9 - success, destroy infrastructure
# 10 - success, ECR created
# 500 - cancelled

# Function to process and return the result as a string
function process_and_return() {
  local url="$1"
  local ports="$2"
  IFS=',' read -ra port_array <<< "$ports"
  result=""
  for p in "${port_array[@]}"; do
    result+="$url:$p\n"
  done
  echo -e "$result"
}

# Function to echo each line of a given variable
echo_lines() {
  local input="$1"
  while IFS= read -r line; do
    echo -e "$line" >> $GITHUB_STEP_SUMMARY
  done <<< "$input"
}

# Process and store URL_OUTPUT:AWS_ELB_LISTEN_PORT in a variable
if [[ -n $URL_OUTPUT ]]; then
  output_elb=$(process_and_return "$URL_OUTPUT" "$AWS_ELB_LISTEN_PORT")
  # Given the case where there is no port specified for the ELB, pass the URL directly
  if [[ -z "$output_elb" ]]; then
    output_elb="$URL_OUTPUT"
  fi
  final_output+="${output_elb}\n"
fi
# Process and store EC2_URL_OUTPUT:AWS_EC2_PORT_LIST in a variable
if [[ -n $AWS_EC2_PORT_LIST ]] && [[ -n $EC2_URL_OUTPUT ]]; then
  output_ec2=$(process_and_return "$EC2_URL_OUTPUT" "$AWS_EC2_PORT_LIST")
  if [[ -z "$output_ec2" ]]; then
    output_ec2="$EC2_URL_OUTPUT"
  fi
  final_output+="${output_ec2}\n"
fi

if [[ -n $ECR_REPO_ARN ]] && [[ -n $ECR_REPO_ID ]] && [[ -n $ECR_REPO_URL ]]; then
  ecr_output+="ECR Repo ARN: ${$ECR_REPO_ARN}\n"
  ecr_output+="ECR Repo ID:  ${$ECR_REPO_ID}\n"
  ecr_output+="ECR Repo URL: ${$ECR_REPO_URL}"
fi

SUMMARY_CODE=0

if [[ $SUCCESS == 'success' ]]; then
  if [[ -n $URL_OUTPUT ]] || [[ -n $EC2_URL_OUTPUT ]]; then
    result_string="## Deploy Complete! :rocket:"
  elif [[ $BITOPS_CODE_ONLY == 'true' ]]; then
    if [[ $BITOPS_CODE_STORE == 'true' ]]; then
      SUMMARY_CODE=6
      result_string="## BitOps Code generated. :tada: 
      Download the code artifact. Will be there for 5 days.
      Keep in mind that for creation, EFS should be created before EC2.
      While destroying, EC2 should be destroyed before EFS. (Due to resources being in use).
      You can change that in the bitops.config.yaml file, or regenerate the code with destroy set."
    else
      SUMMARY_CODE=5
      result_string="## BitOps Code generated. :tada:"
    fi

  elif [[ $TF_STACK_DESTROY == 'true' ]]; then
    if [[ $TF_STATE_BUCKET_DESTROY != 'true' ]]; then
      SUMMARY_CODE=9
      result_string="## VM Destroyed! :boom:
      Infrastructure should be gone now!"
    else
      SUMMARY_CODE=8
      result_string="## VM Destroyed! :boom:
      Buckets and infrastructure should be gone now!"
    fi

  elif [[ $TF_STACK_DESTROY != 'true' && $BITOPS_CODE_ONLY != 'true' ]]; then
    SUMMARY_CODE=4
    result_string="## Deploy finished! But no URL found. :thinking:
    If expecting a URL, please check the logs for possible errors.
    If you consider this is a bug in the Github Action, please submit an issue to our repo."
  fi
elif [[ $SUCCESS == 'cancelled' ]]; then
  SUMMARY_CODE=500
  result_string="## Workflow cancelled :warning:"

else
  SUMMARY_CODE=1
  result_string="## Workflow failed to run :fire:
  Please check the logs for possible errors.
  If you consider this is a bug in the Github Action, please submit an issue to our repo."
fi

echo -e "$result_string" >> $GITHUB_STEP_SUMMARY
if [[ $SUCCESS == 'success' ]]; then
  if [[ -n $final_output ]]; then
    echo "# EC2 URL results #"
    while IFS= read -r line; do
      echo -e "$line" >> $GITHUB_STEP_SUMMARY
    done <<< "$final_output"
  fi
  if [[ -n $ecr_output ]]; then
    echo "# ECR Results #"
    while IFS= read -r line; do
      echo -e "$line" >> $GITHUB_STEP_SUMMARY
    done <<< "$ecr_output"
  fi
fi