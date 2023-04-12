#!/bin/bash

set -e

echo "In generate_bitops_incoming.sh"

function alpha_only() {
  echo "$1" | tr -cd '[:alpha:]' | tr '[:upper:]' '[:lower:]'
}

# The function is long because we try to respect the pre-existent 
# identation in the file, hence parsing multiple options.

function extra_vars_handler() {
  in_boc_file="$1"
  extra_vars_file="$(basename $2)"
  file_lines=$(sed '/^\s*$/d' $in_boc_file | wc -l)

  if [ $file_lines == 1 ] && (grep -q ansible $in_boc_file); then
    echo "  cli:" >> $in_boc_file
    echo "    extra-vars: \"@$extra_vars_file\"" >> $in_boc_file
  else
    if (grep -q "extra-vars" $in_boc_file); then
      extra_vars=$(awk '/extra-vars/ {print $2}' $in_boc_file)
      value=${extra_vars//@/}
      value=${value//\"/}
      if [ "$value" != "$extra_vars_file" ]; then
        echo "There's already an extra-vars definition. File called is: $value"
        echo "Overwriting definition with $extra_vars_file"
        sed -i 's/\(extra-vars:.*\)@'"$value"'/\1'"@$extra_vars_file"'/' $in_boc_file
      fi
    else
      extra_vars_string="extra-vars: \"@$extra_vars_file\""
      # Cleanup possible {} and empty lines, in case we receive cli: {} or options: {}
      sed -i 's|[{}]||g' $in_boc_file
      sed -i '/^[[:space:]]*$/d' $in_boc_file

      if (grep -q "cli" $in_boc_file); then
        num_spaces=$(grep 'cli' $in_boc_file | tr -cd ' ' | wc -c)
        num_spaces_after=$(( $(grep 'cli' -A1 $in_boc_file | tail -n1 | tr -cd ' ' | wc -c) -1 ))
        if [ $num_spaces_after -gt $num_spaces ]; then
          num_spaces=$num_spaces_after
        else
          num_spaces_after=$(( $(grep 'options' -A1 $in_boc_file | tail -n1 | tr -cd ' ' | wc -c) -1 ))
          if [ $num_spaces_after -gt $num_spaces ]; then
            num_spaces=$num_spaces_after
          else
            num_spaces=$(( $num_spaces * 2 ))
          fi
        fi
        extra_vars_string="$(printf "%${num_spaces}s" "")$extra_vars_string"
        num_line=$(( $(grep -n 'cli' $in_boc_file |awk -F ':' '{print $1}') +1 ))
        if [ $num_line -gt $file_lines ]; then
          echo "$extra_vars_string" >> $in_boc_file
        else
          sed -i "${num_line}i\\$extra_vars_string" $in_boc_file
        fi
      else
        if (grep -q "options" $in_boc_file); then
          num_spaces=$(grep 'options' $in_boc_file | tr -cd ' ' | wc -c)
          cli_string="$(printf "%${num_spaces}s" "")cli:"
          echo "$cli_string" >> $in_boc_file

          num_spaces_after=$(( $(grep 'options' -A1 $in_boc_file | tail -n1 | tr -cd ' ' | wc -c) -1 ))
          if [ $num_spaces_after -gt $num_spaces ]; then
            num_spaces=$num_spaces_after
          else
            num_spaces=$(( $num_spaces * 2 ))
          fi

          extra_vars_string="$(printf "%${num_spaces}s" "")"$extra_vars_string""
          echo "$extra_vars_string" >> $in_boc_file
        fi
      fi
    fi
  fi
  echo "Cating BOC file"
  cat $in_boc_file
}


if [ -n "$GH_CALLING_REPO" ]; then
  #  ANSIBLE PART
  echo "Inside ansible part"
  if [ -n "$GH_INPUT_ANSIBLE" ] && [[ "$(alpha_only $ANSIBLE_SKIP)" != "true" ]]; then
    GH_INPUT_ANSIBLE_PATH="$GH_CALLING_REPO/$GH_INPUT_ANSIBLE"
    echo "GH_INPUT_ANSIBLE_PATH -> $GH_INPUT_ANSIBLE_PATH"

    if [ -s "$GH_INPUT_ANSIBLE_PATH/$GH_INPUT_ANSIBLE_PLAYBOOK" ]; then
      if ! [ -s "$GH_INPUT_ANSIBLE_PATH/bitops.config.yaml" ]; then

echo -en "
ansible:
  cli:
    main-playbook: $GH_INPUT_ANSIBLE_PLAYBOOK
  options: {}
" >  $GITHUB_ACTION_PATH/operations/deployment/ansible/$GH_INPUT_ANSIBLE/bitops.config.yaml
 
      fi

      echo " --> Moving $GH_INPUT_ANSIBLE_PATH"
      mv "$GH_INPUT_ANSIBLE_PATH" "$GITHUB_ACTION_PATH/operations/deployment/ansible/incoming"
      
      # Check for existance of extra_vars_file, if so, handle it. 
      if [ -s "$GITHUB_WORKSPACE/$GH_INPUT_ANSIBLE_EXTRA_VARS_FILE" ] && [ -n "$GH_INPUT_ANSIBLE_EXTRA_VARS_FILE" ]; then
        cp "$GITHUB_WORKSPACE/$GH_INPUT_ANSIBLE_EXTRA_VARS_FILE" "${GITHUB_ACTION_PATH}/operations/deployment/ansible/incoming/."
        extra_vars_handler "${GITHUB_ACTION_PATH}/operations/deployment/ansible/incoming/bitops.config.yaml" "$GH_INPUT_ANSIBLE_EXTRA_VARS_FILE"
      fi

      # Add Ansible - Incoming GH to main bitops.config.yaml
echo -en "
    ansible/incoming:
      plugin: ansible
" >> $GITHUB_ACTION_PATH/operations/deployment/bitops.config.yaml
    else
      echo "::error::Couldn't find $GH_INPUT_ANSIBLE_PLAYBOOK inside incoming Ansible folder."
    fi
  fi
  
  # TERRAFORM PART
  # TBC
fi

echo "Cating MAIN bitops.config.yaml"
cat $GITHUB_ACTION_PATH/operations/deployment/bitops.config.yaml