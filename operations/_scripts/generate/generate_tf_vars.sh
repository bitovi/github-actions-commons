#!/bin/bash

set -e

echo "In generate_tf_vars.sh"

# convert 'a,b,c'
# to '["a","b","c"]'
comma_str_to_tf_array () {
  local IFS=','
  local str=$1

  local out=""
  local first_item_flag="1"
  for item in $str; do
    if [ -z $first_item_flag ]; then
      out="${out},"
    fi
    first_item_flag=""

    item="$(echo $item | xargs)"
    out="${out}\"${item}\""
  done
  echo "[${out}]"
}

GITHUB_ORG_NAME=$(echo $GITHUB_REPOSITORY | sed 's/\/.*//')
GITHUB_REPO_NAME=$(echo $GITHUB_REPOSITORY | sed 's/^.*\///')

if [ -n "$GITHUB_HEAD_REF" ]; then
  GITHUB_BRANCH_NAME=${GITHUB_HEAD_REF}
else
  GITHUB_BRANCH_NAME=${GITHUB_REF_NAME}
fi


GITHUB_IDENTIFIER="$($GITHUB_ACTION_PATH/operations/_scripts/generate/generate_identifier.sh)"
echo "GITHUB_IDENTIFIER: [$GITHUB_IDENTIFIER]"

GITHUB_IDENTIFIER_SS="$($GITHUB_ACTION_PATH/operations/_scripts/generate/generate_identifier_supershort.sh)"
echo "GITHUB_IDENTIFIER SS: [$GITHUB_IDENTIFIER_SS]"


# -------------------------------------------------- #
# Generator # 
# Function to generate the variable content based on the fact that it could be empty. 
# This way, we only pass terraform variables that are defined, hence not overwriting terraform defaults. 

generate_var () {
  if [[ -n "$2" ]];then
    echo "$1 = \"$2\""
  fi
}

# Fixed values

ops_repo_environment="ops_repo_environment = \"deployment\""
app_org_name="app_org_name = \"${GITHUB_ORG_NAME}\""
app_repo_name="app_repo_name = \"${GITHUB_REPO_NAME}\""
app_branch_name="app_branch_name = \"${GITHUB_BRANCH_NAME}\""
app_install_root="app_install_root = \"/home/ubuntu\""
security_group_name="security_group_name = \"${GITHUB_IDENTIFIER}\""
aws_resource_identifier="aws_resource_identifier = \"${GITHUB_IDENTIFIER}\""
aws_resource_identifier_supershort="aws_resource_identifier_supershort = \"${GITHUB_IDENTIFIER_SS}\""
aws_security_group_name_pg="aws_security_group_name_pg = \"${GITHUB_IDENTIFIER}-pg\""

# Special cases

aws_ec2_iam_instance_profile=
if [ -n "${AWS_EC2_IAM_INSTANCE_PROFILE}" ]; then
  aws_ec2_iam_instance_profile="aws_ec2_iam_instance_profile =\"${AWS_EC2_IAM_INSTANCE_PROFILE}\""
else
  aws_ec2_iam_instance_profile="aws_ec2_iam_instance_profile =\"${GITHUB_IDENTIFIER}\""
fi

aws_r53_sub_domain_name=
if [ -n "$AWS_R53_SUB_DOMAIN_NAME" ]; then
  aws_r53_sub_domain_name="aws_r53_sub_domain_name = \"$AWS_R53_SUB_DOMAIN_NAME\""
else
  aws_r53_sub_domain_name="aws_r53_sub_domain_name = \"$GITHUB_IDENTIFIER\""
fi

aws_postgres_subnets=
if [ -n "${AWS_POSTGRES_SUBNETS}" ]; then
  aws_postgres_subnets="aws_postgres_subnets = \"$(comma_str_to_tf_array $AWS_POSTGRES_SUBNETS)\""
fi
echo "AWS Postgres subnets: $aws_postgres_subnets"



#-- AWS Specific --#
# aws_resource_identifier=$(generate_var aws_resource_identifier AWS_RESOURCE_IDENTIFIER - Fixed
# aws_resource_identifier_supershort=$(generate_var aws_resource_identifier_supershort AWS_RESOURCE_IDENTIFIER_SUPERSHORT - Fixed
aws_additional_tags=$(generate_var aws_additional_tags $AWS_ADDITIONAL_TAGS)

#-- ENV Files --#
env_aws_secret=$(generate_var env_aws_secret $ENV_AWS_SECRET)

#-- EC2 Instance --#
aws_ec2_ami_id=$(generate_var aws_ec2_ami_id $AWS_EC2_AMI_ID)
# aws_ec2_iam_instance_profile=$(generate_var aws_ec2_iam_instance_profile AWS_EC2_IAM_INSTANCE_PROFILE - Special case
aws_ec2_instance_type=$(generate_var aws_ec2_instance_type $AWS_EC2_INSTANCE_TYPE)
aws_ec2_create_keypair_sm=$(generate_var aws_ec2_create_keypair_sm $AWS_EC2_CREATE_KEYPAIR_SM)
aws_ec2_instance_public_ip=$(generate_var aws_ec2_instance_public_ip $AWS_EC2_INSTANCE_PUBLIC_IP)


#-- AWS Route53 and certs --#
aws_r53_domain_name=$(generate_var aws_r53_domain_name $AWS_R53_DOMAIN_NAME)
# aws_r53_sub_domain_name=$(generate_var aws_r53_sub_domain_name $AWs_R53_SUB_DOMAIN_NAME)  - Special case
aws_r53_root_domain_deploy=$(generate_var aws_r53_root_domain_deploy $AWS_R53_ROOT_DOMAIN_DEPLOY)
aws_r53_enable_cert=$(generate_var aws_r53_enable_cert $AWS_R53_ENABLE_CERT)
aws_r53_cert_arn=$(generate_var aws_r53_cert_arn $AWS_R53_CERT_ARN)
aws_r53_create_root_cert=$(generate_var aws_r53_create_root_cert $AWS_R53_CREATE_ROOT_CERT)
aws_r53_create_sub_cert=$(generate_var aws_r53_create_sub_cert $AWS_R53_CREATE_SUB_CERT)

#-- AWS ELB --#
aws_elb_app_port=$(generate_var aws_elb_app_port $AWS_ELB_APP_PORT)
aws_elb_listen_port=$(generate_var aws_elb_listen_port $AWS_ELB_LISTEN_PORT)
aws_elb_healthcheck=$(generate_var aws_elb_healthcheck $AWS_ELB_HEALTHCHECK)

#-- AWS EFS --#
if [[ $AWS_EFS_CREATE = true ]]; then
  aws_efs_create=$(generate_var aws_efs_create $AWS_EFS_CREATE)
  aws_efs_create_ha=$(generate_var aws_efs_create_ha $AWS_EFS_CREATE_HA)
  aws_efs_create_replica=$(generate_var aws_efs_create_replica $AWS_EFS_CREATE_REPLICA)
  aws_efs_enable_backup_policy=$(generate_var aws_efs_enable_backup_policy $AWS_EFS_ENABLE_BACKUP_POLICY)
  aws_efs_zone_mapping=$(generate_var aws_efs_zone_mapping $AWS_EFS_ZONE_MAPPING)
  aws_efs_transition_to_inactive=$(generate_var aws_efs_transition_to_inactive $AWS_EFS_TRANSITION_TO_INACTIVE)
  aws_efs_replication_destination=$(generate_var aws_efs_replication_destination $AWS_EFS_REPLICATION_DESTINATION)
  aws_efs_mount_id=$(generate_var aws_efs_mount_id $AWS_EFS_MOUNT_ID)
  aws_efs_mount_security_group_id=$(generate_var aws_efs_mount_security_group_id $AWS_EFS_MOUNT_SECURITY_GROUP_ID)
  aws_efs_mount_target=$(generate_var aws_efs_mount_target $AWS_EFS_MOUNT_TARGET)
  aws_efs_ec2_mount_point=$(generate_var aws_efs_ec2_mount_point $AWS_EFS_EC2_MOUNT_POINT)
fi

#-- RDS --#
if [[ $AWS_POSTGRES_ENABLE = true ]]; then
  # aws_security_group_name_pg=$(generate_var aws_security_group_name_pg $AWS_SECURITY_GROUP_NAME_PG) - Fixed
  aws_postgres_enable=$(generate_var aws_postgres_enable $AWS_POSTGRES_ENABLE)
  aws_postgres_engine=$(generate_var aws_postgres_engine $AWS_POSTGRES_ENGINE)
  aws_postgres_engine_version=$(generate_var aws_postgres_engine_version $AWS_POSTGRES_ENGINE_VERSION)
  aws_postgres_instance_class=$(generate_var aws_postgres_instance_class $AWS_POSTGRES_INSTANCE_CLASS)
  # aws_postgres_subnets=$(generate_var aws_postgres_subnets $AWS_POSTGRES_SUBNETS) - Special case
  aws_postgres_database_name=$(generate_var aws_postgres_database_name $AWS_POSTGRES_DATABASE_NAME)
  aws_postgres_database_port=$(generate_var aws_postgres_database_port $AWS_POSTGRES_DATABASE_PORT)
fi

docker_efs_mount_target=$(generate_var docker_efs_mount_target $DOCKER_EFS_MOUNT_TARGET)


#-- Application --#
# ops_repo_environment=$(generate_var ops_repo_environment OPS_REPO_ENVIRONMENT - Fixed
# app_org_name=$(generate_var app_org_name APP_ORG_NAME - Fixed
# app_repo_name=$(generate_var app_repo_name APP_REPO_NAME - Fixed
# app_branch_name=$(generate_var app_branch_name APP_BRANCH_NAME - Fixed
# app_install_root=$(generate_var app_install_root APP_INSTALL_ROOT - Fixed
#-- Load Balancer --#

#-- Logging --#
lb_access_bucket_name=$(generate_var lb_access_bucket_name $LB_LOGS_BUCKET)
#-- Security Groups --#
security_group_name=$(generate_var security_group_name $SECURITY_GROUP_NAME)



# -------------------------------------------------- #

echo "
#-- AWS --#
$aws_resource_identifier
$aws_resource_identifier_supershort
$aws_additional_tags

#-- ENV --#
$env_aws_secret

#-- EC2 --#
$aws_ec2_ami_id
$aws_ec2_iam_instance_profile
$aws_ec2_instance_type
$aws_ec2_create_keypair_sm
$aws_ec2_instance_public_ip

#-- R53 --#
$aws_r53_domain_name
$aws_r53_sub_domain_name
$aws_r53_root_domain_deploy
$aws_r53_enable_cert
$aws_r53_cert_arn
$aws_r53_create_root_cert
$aws_r53_create_sub_cert

#-- ELB --#
$aws_elb_app_port
$aws_elb_listen_port
$aws_elb_healthcheck
$lb_access_bucket_name

#-- EFS --#
$aws_efs_create
$aws_efs_create_ha
$aws_efs_create_replica
$aws_efs_enable_backup_policy
$aws_efs_zone_mapping
$aws_efs_transition_to_inactive
$aws_efs_replication_destination
$aws_efs_mount_id
$aws_efs_mount_security_group_id
$aws_efs_mount_target
$aws_efs_ec2_mount_point

#-- RDS --#
$aws_security_group_name_pg
$aws_postgres_enable
$aws_postgres_engine
$aws_postgres_engine_version
$aws_postgres_instance_class
$aws_postgres_subnets
$aws_postgres_database_name
$aws_postgres_database_port

$docker_efs_mount_target

#-- Application --#
$ops_repo_environment
$app_org_name
$app_repo_name
$app_branch_name
$app_install_root

#-- Security Groups --#
$security_group_name

" > "${GITHUB_ACTION_PATH}/operations/deployment/terraform/terraform.tfvars"