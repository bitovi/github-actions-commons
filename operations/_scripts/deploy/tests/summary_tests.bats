#!/usr/bin/env bats

# see here for summary_codes
export file_under_test=../summary.sh

# we don't care about the output of the summary script - just the code
# so we can use a dummy file
export GITHUB_OUTPUT=./test.txt
teardown() {
  rm -f "$SUMMARY_CODE_OUTPUT" "$GITHUB_OUTPUT"
}

@test "1. Test case: SUCCESS is true, URL_OUTPUT is not empty" {
  # Set the environment variables
  export SUCCESS='true'
  export URL_OUTPUT='example.com'

  # Run the script
  source $file_under_test

  # Read the content of the output file
  result=$(<"$SUMMARY_CODE_OUTPUT")

  # Check if the summary result code is correct
  expected_result=0

  # Compare the results
  [[ "$result" = "$expected_result" ]]
}

@test "2. Test case: SUCCESS is true, URL_OUTPUT is empty, BITOPS_CODE_ONLY is true, BITOPS_CODE_STORE is true" {
  export SUCCESS='true'
  export URL_OUTPUT=''
  export BITOPS_CODE_ONLY='true'
  export BITOPS_CODE_STORE='true'

  source $file_under_test
  result=$(<"$SUMMARY_CODE_OUTPUT")
  expected_result=6

  [[ "$result" = "$expected_result" ]]
}

@test "3. Test case: SUCCESS is true, URL_OUTPUT is empty, BITOPS_CODE_ONLY is true, BITOPS_CODE_STORE is false" {
  export SUCCESS='true'
  export URL_OUTPUT=''
  export BITOPS_CODE_ONLY='true'
  export BITOPS_CODE_STORE='false'

  source $file_under_test
  result=$(<"$SUMMARY_CODE_OUTPUT")
  expected_result=5

  [[ "$result" = "$expected_result" ]]
}

@test "4. Test case: SUCCESS is true, URL_OUTPUT is empty, TF_STACK_DESTROY is true, TF_STATE_BUCKET_DESTROY is false" {
  export SUCCESS='true'
  export URL_OUTPUT=''
  export BITOPS_CODE_ONLY='false'
  export TF_STACK_DESTROY='true'
  export TF_STATE_BUCKET_DESTROY='false'

  source $file_under_test
  result=$(<"$SUMMARY_CODE_OUTPUT")
  expected_result=9

  [[ "$result" = "$expected_result" ]]
}

@test "5. Test case: SUCCESS is true, URL_OUTPUT is empty, TF_STACK_DESTROY is true, TF_STATE_BUCKET_DESTROY is true" {
  export SUCCESS='true'
  export URL_OUTPUT=''
  export BITOPS_CODE_ONLY='false'
  export TF_STACK_DESTROY='true'
  export TF_STATE_BUCKET_DESTROY='true'

  source $file_under_test
  result=$(<"$SUMMARY_CODE_OUTPUT")
  expected_result=8

  [[ "$result" = "$expected_result" ]]
}

@test "6. Test case: SUCCESS is true, URL_OUTPUT is empty, BITOPS_CODE_ONLY is false, TF_STACK_DESTROY is false" {
  export SUCCESS='true'
  export URL_OUTPUT=''
  export BITOPS_CODE_ONLY='false'
  export TF_STACK_DESTROY='false'
  export BITOPS_CODE_STORE='false'

  source $file_under_test
  result=$(<"$SUMMARY_CODE_OUTPUT")
  expected_result=4

  [[ "$result" = "$expected_result" ]]
}

@test "7. Test case: SUCCESS is false" {
  export SUCCESS='false'

  source $file_under_test
  result=$(<"$SUMMARY_CODE_OUTPUT")
  expected_result=1

  [[ "$result" = "$expected_result" ]]
}
