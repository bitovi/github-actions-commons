#!/usr/bin/env bats

# see here for summary_codes
# this runs once before all tests
setup_file() {
  export file_under_test=$GITHUB_WORKSPACE/operations/_scripts/deploy/summary.sh
  export GITHUB_STEP_SUMMARY=$(mktemp ./test.XXX)
  export GITHUB_OUTPUT=$(mktemp ./test.XXX)
}

# this runs once after all tests
teardown_file() {
  rm -f $GITHUB_STEP_SUMMARY $GITHUB_OUTPUT
}

function runTest() {
  # Run the script
  source $file_under_test

  # take the passed-in expected result code
  expected_result=$1

  # Compare the results
  # SUMMARY_CODE is set in summary script as an output
  source $GITHUB_OUTPUT
  [[ "$SUMMARY_CODE" = "$expected_result" ]]
}

@test "SUCCESS is true, URL_OUTPUT is not empty" {
  # Set the environment variables
  export SUCCESS='success'
  export URL_OUTPUT='example.com'

  # Run the test and pass in the expected result code
  runTest 0
}

@test "SUCCESS is true, URL_OUTPUT is empty, BITOPS_CODE_ONLY is true, BITOPS_CODE_STORE is true" {
  export SUCCESS='success'
  export URL_OUTPUT=''
  export BITOPS_CODE_ONLY='true'
  export BITOPS_CODE_STORE='true'

  runTest 6
}

@test "SUCCESS is true, URL_OUTPUT is empty, BITOPS_CODE_ONLY is true, BITOPS_CODE_STORE is false" {
  export SUCCESS='success'
  export URL_OUTPUT=''
  export BITOPS_CODE_ONLY='true'
  export BITOPS_CODE_STORE='false'

  runTest 5
}

@test "SUCCESS is true, URL_OUTPUT is empty, TF_STACK_DESTROY is true, TF_STATE_BUCKET_DESTROY is false" {
  export SUCCESS='success'
  export URL_OUTPUT=''
  export BITOPS_CODE_ONLY='false'
  export TF_STACK_DESTROY='true'
  export TF_STATE_BUCKET_DESTROY='false'

  runTest 9
}

@test "SUCCESS is true, URL_OUTPUT is empty, TF_STACK_DESTROY is true, TF_STATE_BUCKET_DESTROY is true" {
  export SUCCESS='success'
  export URL_OUTPUT=''
  export BITOPS_CODE_ONLY='false'
  export TF_STACK_DESTROY='true'
  export TF_STATE_BUCKET_DESTROY='true'

  runTest 8
}

@test "SUCCESS is true, URL_OUTPUT is empty, TF_STACK_DESTROY is false, TF_STATE_BUCKET_DESTROY is true" {
  export SUCCESS='success'
  export URL_OUTPUT=''
  export BITOPS_CODE_ONLY='false'
  export TF_STACK_DESTROY='false'
  export TF_STATE_BUCKET_DESTROY='true'
  export ECR_REPO_ARN='something'
  export ECR_REPO_ID='something'
  export ECR_REPO_URL='something'

  runTest 10
}

@test "SUCCESS is true, URL_OUTPUT is empty, BITOPS_CODE_ONLY is false, TF_STACK_DESTROY is false" {
  export SUCCESS='success'
  export URL_OUTPUT=''
  export BITOPS_CODE_ONLY='false'
  export TF_STACK_DESTROY='false'
  export BITOPS_CODE_STORE='false'

  runTest 4
}

@test "SUCCESS is false" {
  export SUCCESS='false'

  runTest 1

}

@test "SUCCESS is 'cancelled'" {
  export SUCCESS='cancelled'

  runTest 500
}
