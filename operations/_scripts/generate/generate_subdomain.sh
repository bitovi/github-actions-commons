#!/bin/bash

set -e

if [ -z "${AWS_R53_SUB_DOMAIN_NAME}" ]; then
  if [ -n "${GITHUB_IDENTIFIER}" ]; then
    GITHUB_IDENTIFIER="$($GITHUB_ACTION_PATH/operations/_scripts/generate/generate_identifier.sh)"
  fi
  export AWS_R53_SUB_DOMAIN_NAME="${GITHUB_IDENTIFIER}"
fi

echo "$AWS_R53_SUB_DOMAIN_NAME"