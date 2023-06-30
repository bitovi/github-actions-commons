#!/usr/bin/env bats

export file_under_test=../summary.sh
export GITHUB_OUTPUT='output.txt'

teardown() {
  rm -f "$GITHUB_OUTPUT"
}

@test "Test case: SUCCESS is true, URL_OUTPUT is not empty" {
  # Set the environment variables
  export SUCCESS='true'
  export URL_OUTPUT='example.com'

  # Run the script
  source $file_under_test

  # Read the content of the output file
  result=$(<"$GITHUB_OUTPUT")

  # Check if the expected result is appended to the output file
  expected_result="## VM Created! :rocket:
    example.com"

  # Compare the results
  [[ "${result}" = "${expected_result}" ]]
}

@test "Test case: SUCCESS is true, URL_OUTPUT is empty, BITOPS_CODE_ONLY is true, BITOPS_CODE_STORE is true" {
  export SUCCESS='true'
  export URL_OUTPUT=''
  export BITOPS_CODE_ONLY='true'
  export BITOPS_CODE_STORE='true'

  source $file_under_test
  result=$(<"$GITHUB_OUTPUT")

  expected_result="## BitOps Code generated. :tada: 
      Download the code artifact. Will be there for 5 days.
      Keep in mind that for creation, EFS should be created before EC2.
      While destroying, EC2 should be destroyed before EFS. (Due to resources being in use).
      You can change that in the bitops.config.yaml file, or regenerate the code with destroy set."

  [[ "${result}" = "${expected_result}" ]]
}

@test "Test case: SUCCESS is true, URL_OUTPUT is empty, BITOPS_CODE_ONLY is true, BITOPS_CODE_STORE is false" {
  export SUCCESS='true'
  export URL_OUTPUT=''
  export BITOPS_CODE_ONLY='true'
  export BITOPS_CODE_STORE='false'

  source $file_under_test
  result=$(<"$GITHUB_OUTPUT")

  
  expected_result="## BitOps Code generated. :tada:"
  [[ "${result}" = "${expected_result}" ]]
}

@test "Test case: SUCCESS is true, URL_OUTPUT is empty, TF_STACK_DESTROY is true, TF_STATE_BUCKET_DESTROY is false" {
  export SUCCESS='true'
  export URL_OUTPUT=''
  export BITOPS_CODE_ONLY='false'
  export TF_STACK_DESTROY='true'
  export TF_STATE_BUCKET_DESTROY='false'

  source $file_under_test
  result=$(<"$GITHUB_OUTPUT")

  
  expected_result="## VM Destroyed! :boom:
      Infrastructure should be gone now!"
  [[ "${result}" = "${expected_result}" ]]
}

@test "Test case: SUCCESS is true, URL_OUTPUT is empty, TF_STACK_DESTROY is true, TF_STATE_BUCKET_DESTROY is true" {
  export SUCCESS='true'
  export URL_OUTPUT=''
  export BITOPS_CODE_ONLY='false'
  export TF_STACK_DESTROY='true'
  export TF_STATE_BUCKET_DESTROY='true'

  source $file_under_test
  result=$(<"$GITHUB_OUTPUT")

  
  expected_result="## VM Destroyed! :boom:
      Buckets and infrastructure should be gone now!"
  [[ "${result}" = "${expected_result}" ]]
}

@test "Test case: SUCCESS is true, URL_OUTPUT is empty, BITOPS_CODE_ONLY is false, TF_STACK_DESTROY is false" {
  export SUCCESS='true'
  export URL_OUTPUT=''
  export BITOPS_CODE_ONLY='false'
  export TF_STACK_DESTROY='false'
  export BITOPS_CODE_STORE='false'

  source $file_under_test
  result=$(<"$GITHUB_OUTPUT")

  
  expected_result="## Deploy finished! But no URL found. :thinking:
    If expecting a URL, please check the logs for possible  errors.
    If you consider this is a bug in the Github Action, please submit an issue to our repo."
  [[ "${result}" = "${expected_result}" ]]
}

@test "Test case: SUCCESS is false" {
  export SUCCESS='false'

  source $file_under_test
  result=$(<"$GITHUB_OUTPUT")

  
  expected_result="## Workflow failed to run :fire:
  Please check the logs for possible errors.
  If you consider this is a bug in the Github Action, please submit an issue to our repo."
  [[ "${result}" = "${expected_result}" ]]
}
