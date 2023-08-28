#!/bin/bash

set -e

echo "In generate_vars_terraform.sh"

# convert 'a,b,c'
# to '["a","b","c"]'
function comma_str_to_tf_array () {
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

# -------------------------------------------------- #
# Generator # 
# Function to generate the variable content based on the fact that it could be empty. 
# This way, we only pass terraform variables that are defined, hence not overwriting terraform defaults. 

# Removes anything from the variable and leave only alpha characters, and lowers them. This is to validate if boolean.
function alpha_only() {
    echo "$1" | tr -cd '[:alpha:]' | tr '[:upper:]' '[:lower:]'
}

function generate_var () {
  if [[ -n "$2" ]];then
    if [[ $(alpha_only "$2") == "true" ]] || [[ $(alpha_only "$2") == "false" ]]; then
      echo "$1 = $(alpha_only $2)"
    else
      echo "$1 = \"$2\""
    fi
  fi
}

# Fixed values - Values that are hardcoded or come from other variables.

ops_repo_environment="ops_repo_environment = \"deployment\""
app_org_name="app_org_name = \"${GITHUB_ORG_NAME}\""
app_repo_name="app_repo_name = \"${GITHUB_REPO_NAME}\""
app_branch_name="app_branch_name = \"${GITHUB_BRANCH_NAME}\""
app_install_root="app_install_root = \"/home/ubuntu\""
aws_resource_identifier="aws_resource_identifier = \"${GITHUB_IDENTIFIER}\""
aws_resource_identifier_supershort="aws_resource_identifier_supershort = \"${GITHUB_IDENTIFIER_SS}\""

# Special cases - Values that need fallback values or special calculation

aws_ec2_iam_instance_profile=
if [ -n "${AWS_EC2_IAM_INSTANCE_PROFILE}" ]; then
  aws_ec2_iam_instance_profile="aws_ec2_iam_instance_profile =\"${AWS_EC2_IAM_INSTANCE_PROFILE}\""
else
  aws_ec2_iam_instance_profile="aws_ec2_iam_instance_profile =\"${GITHUB_IDENTIFIER}\""
fi

aws_r53_sub_domain_name=
if [ -n "${AWS_R53_SUB_DOMAIN_NAME}" ]; then
  aws_r53_sub_domain_name="aws_r53_sub_domain_name = \"${AWS_R53_SUB_DOMAIN_NAME}\""
else
  aws_r53_sub_domain_name="aws_r53_sub_domain_name = \"${GITHUB_IDENTIFIER}\""
fi

aws_aurora_subnets=
if [ -n "${AWS_AURORA_SUBNETS}" ]; then
  aws_aurora_subnets="aws_aurora_subnets = \"$(comma_str_to_tf_array $AWS_AURORA_SUBNETS)\""
fi

# If the name is true, set it up to be the GH ID - If not, if it's not false, it's the snap name.
if [ -n "$AWS_AURORA_DATABASE_FINAL_SNAPSHOT" ];then
  if [[ $(alpha_only "$AWS_AURORA_DATABASE_FINAL_SNAPSHOT") == "true" ]]; then
    aws_aurora_database_final_snapshot="aws_aurora_database_final_snapshot = \"${GITHUB_IDENTIFIER}\""
  else
    if [[ $(alpha_only "$AWS_AURORA_DATABASE_FINAL_SNAPSHOT") != "false" ]]; then
      aws_aurora_database_final_snapshot="aws_aurora_database_final_snapshot = \"${AWS_AURORA_DATABASE_FINAL_SNAPSHOT}\""
    fi
  fi
fi

aws_eks_cluster_name=
if [ -n "${AWS_EKS_CLUSTER_NAME}" ]; then
  aws_eks_cluster_name="aws_eks_cluster_name = \"${AWS_EKS_CLUSTER_NAME}\""
else
  aws_eks_cluster_name="aws_eks_cluster_name = \"${GITHUB_IDENTIFIER}-cluster\""
fi

#-- AWS Specific --#
# aws_resource_identifier=$(generate_var aws_resource_identifier AWS_RESOURCE_IDENTIFIER - Fixed
# aws_resource_identifier_supershort=$(generate_var aws_resource_identifier_supershort AWS_RESOURCE_IDENTIFIER_SUPERSHORT - Fixed
aws_additional_tags=$(generate_var aws_additional_tags $AWS_ADDITIONAL_TAGS)

#-- ENV Files --#
if [ -n "$ENV_AWS_SECRET" ]; then
  env_aws_secret=$(generate_var env_aws_secret $ENV_AWS_SECRET)
fi

#-- EC2 Instance --#
if [[ $(alpha_only "$AWS_EC2_INSTANCE_CREATE") == true ]]; then
  aws_ec2_instance_create=$(generate_var aws_ec2_instance_create $AWS_EC2_INSTANCE_CREATE)
  aws_ec2_ami_filter=$(generate_var aws_ec2_ami_filter $AWS_EC2_AMI_FILTER)
  aws_ec2_ami_owner=$(generate_var aws_ec2_ami_owner $AWS_EC2_AMI_OWNER)
  aws_ec2_ami_id=$(generate_var aws_ec2_ami_id $AWS_EC2_AMI_ID)
  aws_ec2_ami_update=$(generate_var aws_ec2_ami_update $AWS_EC2_AMI_UPDATE)
  # aws_ec2_iam_instance_profile=$(generate_var aws_ec2_iam_instance_profile AWS_EC2_IAM_INSTANCE_PROFILE - Special case
  aws_ec2_instance_type=$(generate_var aws_ec2_instance_type $AWS_EC2_INSTANCE_TYPE)
  aws_ec2_instance_root_vol_size=$(generate_var aws_ec2_instance_root_vol_size $AWS_EC2_INSTANCE_ROOT_VOL_SIZE)
  aws_ec2_instance_root_vol_preserve=$(generate_var aws_ec2_instance_root_vol_preserve $AWS_EC2_INSTANCE_ROOT_VOL_PRESERVE)
  aws_ec2_security_group_name=$(generate_var aws_ec2_security_group_name $AWS_EC2_SECURITY_GROUP_NAME)
  aws_ec2_create_keypair_sm=$(generate_var aws_ec2_create_keypair_sm $AWS_EC2_CREATE_KEYPAIR_SM)
  aws_ec2_instance_public_ip=$(generate_var aws_ec2_instance_public_ip $AWS_EC2_INSTANCE_PUBLIC_IP)
  aws_ec2_port_list=$(generate_var aws_ec2_port_list $AWS_EC2_PORT_LIST)
  aws_ec2_user_data_replace_on_change=$(generate_var aws_ec2_user_data_replace_on_change $AWS_EC2_USER_DATA_REPLACE_ON_CHANGE)
  aws_ec2_additional_tags=$(generate_var aws_ec2_additional_tags $AWS_EC2_ADDITIONAL_TAGS)
fi

#-- VPC Handling --# 
if [[ $(alpha_only "$AWS_VPC_CREATE") == true ]]; then
  aws_vpc_create=$(generate_var aws_vpc_create $AWS_VPC_CREATE)
  aws_vpc_name=$(generate_var aws_vpc_name $AWS_VPC_NAME)
  aws_vpc_cidr_block=$(generate_var aws_vpc_cidr_block $AWS_VPC_CIDR_BLOCK)
  aws_vpc_public_subnets=$(generate_var aws_vpc_public_subnets $AWS_VPC_PUBLIC_SUBNETS)
  aws_vpc_private_subnets=$(generate_var aws_vpc_private_subnets $AWS_VPC_PRIVATE_SUBNETS)
  aws_vpc_availability_zones=$(generate_var aws_vpc_availability_zones $AWS_VPC_AVAILABILITY_ZONES)
  aws_vpc_additional_tags=$(generate_var aws_vpc_additional_tags $AWS_VPC_ADDITIONAL_TAGS)
fi
aws_vpc_id=$(generate_var aws_vpc_id $AWS_VPC_ID)
aws_vpc_subnet_id=$(generate_var aws_vpc_subnet_id $AWS_VPC_SUBNET_ID)

#-- AWS Route53 and certs --#
if [[ $(alpha_only "$AWS_R53_ENABLE") == true ]]; then
  aws_r53_enable=$(generate_var aws_r53_enable $AWS_R53_ENABLE)
  aws_r53_domain_name=$(generate_var aws_r53_domain_name $AWS_R53_DOMAIN_NAME)
  # aws_r53_sub_domain_name=$(generate_var aws_r53_sub_domain_name $AWs_R53_SUB_DOMAIN_NAME)  - Special case
  aws_r53_root_domain_deploy=$(generate_var aws_r53_root_domain_deploy $AWS_R53_ROOT_DOMAIN_DEPLOY)
fi
if [[ $(alpha_only "$AWS_R53_ENABLE") == true ]] || [[ $(alpha_only "$AWS_R53_ENABLE_CERT") == true ]]; then
  aws_r53_additional_tags=$(generate_var aws_r53_additional_tags $AWS_R53_ADDITIONAL_TAGS)
fi
if [[ $(alpha_only "$AWS_R53_ENABLE_CERT") == true ]]; then
  aws_r53_enable_cert=$(generate_var aws_r53_enable_cert $AWS_R53_ENABLE_CERT)
  aws_r53_cert_arn=$(generate_var aws_r53_cert_arn $AWS_R53_CERT_ARN)
  aws_r53_create_root_cert=$(generate_var aws_r53_create_root_cert $AWS_R53_CREATE_ROOT_CERT)
  aws_r53_create_sub_cert=$(generate_var aws_r53_create_sub_cert $AWS_R53_CREATE_SUB_CERT)
fi

#-- AWS ELB --#
if [[ $(alpha_only "$AWS_ELB_CREATE") == true ]]; then
  aws_elb_create=$(generate_var aws_elb_create $AWS_ELB_CREATE)
  aws_elb_security_group_name=$(generate_var aws_elb_security_group_name $AWS_ELB_SECURITY_GROUP_NAME)
  aws_elb_app_port=$(generate_var aws_elb_app_port $AWS_ELB_APP_PORT)
  aws_elb_app_protocol=$(generate_var aws_elb_app_protocol $AWS_ELB_APP_PROTOCOL)
  aws_elb_listen_port=$(generate_var aws_elb_listen_port $AWS_ELB_LISTEN_PORT)
  aws_elb_listen_protocol=$(generate_var aws_elb_listen_protocol $AWS_ELB_LISTEN_PROTOCOL)
  aws_elb_healthcheck=$(generate_var aws_elb_healthcheck $AWS_ELB_HEALTHCHECK)
  aws_elb_additional_tags=$(generate_var aws_elb_additional_tags $AWS_ELB_ADDITIONAL_TAGS)
fi

#-- AWS EFS --#
if [[ $(alpha_only "$AWS_EFS_ENABLE") == true ]]; then
  aws_efs_enable=$(generate_var aws_efs_enable $AWS_EFS_ENABLE)
  aws_efs_create=$(generate_var aws_efs_create $AWS_EFS_CREATE)
  aws_efs_create_ha=$(generate_var aws_efs_create_ha $AWS_EFS_CREATE_HA)
  aws_efs_fs_id=$(generate_var aws_efs_fs_id $AWS_EFS_FS_ID)
  aws_efs_vpc_id=$(generate_var aws_efs_vpc_id $AWS_EFS_VPC_ID)
  aws_efs_subnet_ids=$(generate_var aws_efs_subnet_ids $AWS_EFS_SUBNET_IDS)
  aws_efs_security_group_name=$(generate_var aws_efs_security_group_name $AWS_EFS_SECURITY_GROUP_NAME)
  aws_efs_create_replica=$(generate_var aws_efs_create_replica $AWS_EFS_CREATE_REPLICA)
  aws_efs_replication_destination=$(generate_var aws_efs_replication_destination $AWS_EFS_REPLICATION_DESTINATION)
  aws_efs_enable_backup_policy=$(generate_var aws_efs_enable_backup_policy $AWS_EFS_ENABLE_BACKUP_POLICY)
  aws_efs_transition_to_inactive=$(generate_var aws_efs_transition_to_inactive $AWS_EFS_TRANSITION_TO_INACTIVE)
  aws_efs_mount_target=$(generate_var aws_efs_mount_target $AWS_EFS_MOUNT_TARGET)
  aws_efs_ec2_mount_point=$(generate_var aws_efs_ec2_mount_point $AWS_EFS_EC2_MOUNT_POINT)
  aws_efs_additional_tags=$(generate_var aws_efs_additional_tags $AWS_EFS_ADDITIONAL_TAGS)
fi

#-- RDS --#
if [[ $(alpha_only "$AWS_AURORA_ENABLE") == true ]]; then
  aws_aurora_enable=$(generate_var aws_aurora_enable $AWS_AURORA_ENABLE)
  aws_aurora_engine=$(generate_var aws_aurora_engine $AWS_AURORA_ENGINE)
  aws_aurora_engine_version=$(generate_var aws_aurora_engine_version $AWS_AURORA_ENGINE_VERSION)
  aws_aurora_database_group_family=$(generate_var aws_aurora_database_group_family $AWS_AURORA_DATABASE_GROUP_FAMILY)
  aws_aurora_instance_class=$(generate_var aws_aurora_instance_class $AWS_AURORA_INSTANCE_CLASS)
  aws_aurora_security_group_name=$(generate_var aws_aurora_security_group_name $AWS_AURORA_SECURITY_GROUP_NAME )
  # aws_aurora_subnets=$(generate_var aws_aurora_subnets $AWS_AURORA_SUBNETS) - Special case
  aws_aurora_cluster_name=$(generate_var aws_aurora_cluster_name $AWS_AURORA_CLUSTER_NAME)
  aws_aurora_database_name=$(generate_var aws_aurora_database_name $AWS_AURORA_DATABASE_NAME)
  aws_aurora_database_port=$(generate_var aws_aurora_database_port $AWS_AURORA_DATABASE_PORT)
  aws_aurora_restore_snapshot=$(generate_var aws_aurora_restore_snapshot $AWS_AURORA_RESTORE_SNAPSHOT)
  aws_aurora_snapshot_name=$(generate_var aws_aurora_snapshot_name $AWS_AURORA_SNAPSHOT_NAME)
  aws_aurora_snapshot_overwrite=$(generate_var aws_aurora_snapshot_overwrite $AWS_AURORA_SNAPSHOT_OVERWRITE)
  aws_aurora_database_protection=$(generate_var aws_aurora_database_protection $AWS_AURORA_DATABASE_PROTECTION )
  # aws_aurora_database_final_snapshot=$(generate_var aws_aurora_database_final_snapshot $AWS_AURORA_DATABASE_FINAL_SNAPSHOT ) - Special case
  aws_aurora_additional_tags=$(generate_var aws_aurora_additional_tags $AWS_AURORA_ADDITIONAL_TAGS)
fi

#-- EKS Cluster --#
if [[ $(alpha_only "$AWS_EKS_CREATE") == true ]]; then
  aws_eks_create=$(generate_var aws_eks_create $AWS_EKS_CREATE)
  aws_eks_region=$(generate_var aws_eks_region $AWS_EKS_REGION)
  aws_eks_security_group_name_master=$(generate_var aws_eks_security_group_name_master $AWS_EKS_SECURITY_GROUP_NAME_MASTER)
  aws_eks_security_group_name_worker=$(generate_var aws_eks_security_group_name_worker $AWS_EKS_SECURITY_GROUP_NAME_WORKER)
  aws_eks_environment=$(generate_var aws_eks_environment $AWS_EKS_ENVIRONMENT)
  aws_eks_stackname=$(generate_var aws_eks_stackname $AWS_EKS_STACKNAME)
  aws_eks_cidr_block=$(generate_var aws_eks_cidr_block $AWS_EKS_CIDR_BLOCK)
  aws_eks_workstation_cidr=$(generate_var aws_eks_workstation_cidr $AWS_EKS_WORKSTATION_CIDR)
  aws_eks_availability_zones=$(generate_var aws_eks_availability_zones $AWS_EKS_AVAILABILITY_ZONES)
  aws_eks_private_subnets=$(generate_var aws_eks_private_subnets $AWS_EKS_PRIVATE_SUBNETS)
  aws_eks_public_subnets=$(generate_var aws_eks_public_subnets $AWS_EKS_PUBLIC_SUBNETS)
  #aws_eks_cluster_name=$(generate_var aws_eks_cluster_name $AWS_EKS_CLUSTER_NAME)
  aws_eks_cluster_log_types=$(generate_var aws_eks_cluster_log_types $AWS_EKS_CLUSTER_LOG_TYPES)
  aws_eks_cluster_version=$(generate_var aws_eks_cluster_version $AWS_EKS_CLUSTER_VERSION)
  aws_eks_instance_type=$(generate_var aws_eks_instance_type $AWS_EKS_INSTANCE_TYPE)
  aws_eks_instance_ami_id=$(generate_var aws_eks_instance_ami_id $AWS_EKS_INSTANCE_AMI_ID)
  aws_eks_instance_user_data_file=$(generate_var aws_eks_instance_user_data_file $AWS_EKS_INSTANCE_USER_DATA_FILE)
  aws_eks_ec2_key_pair=$(generate_var aws_eks_ec2_key_pair $AWS_EKS_EC2_KEY_PAIR)
  aws_eks_store_keypair_sm=$(generate_var aws_eks_store_keypair_sm $AWS_EKS_STORE_KEYPAIR_SM)
  aws_eks_desired_capacity=$(generate_var aws_eks_desired_capacity $AWS_EKS_DESIRED_CAPACITY)
  aws_eks_max_size=$(generate_var aws_eks_max_size $AWS_EKS_MAX_SIZE)
  aws_eks_min_size=$(generate_var aws_eks_min_size $AWS_EKS_MIN_SIZE)
  aws_eks_additional_tags=$(generate_var aws_eks_additional_tags $AWS_EKS_ADDITIONAL_TAGS)
fi

#-- ANSIBLE --#
if [[ "$(alpha_only $ANSIBLE_SKIP)" == "true" ]]; then
  ansible_skip=$(generate_var ansible_skip $ANSIBLE_SKIP)
fi

if [[ $(alpha_only "$DOCKER_INSTALL") == true ]]; then
  docker_install=$(generate_var docker_install $DOCKER_INSTALL)
  docker_remove_orphans=$(generate_var docker_remove_orphans $DOCKER_REMOVE_ORPHANS)
  docker_efs_mount_target=$(generate_var docker_efs_mount_target $DOCKER_EFS_MOUNT_TARGET)
fi

#-- Application --#
# ops_repo_environment=$(generate_var ops_repo_environment OPS_REPO_ENVIRONMENT - Fixed
# app_org_name=$(generate_var app_org_name APP_ORG_NAME - Fixed
# app_repo_name=$(generate_var app_repo_name APP_REPO_NAME - Fixed
# app_branch_name=$(generate_var app_branch_name APP_BRANCH_NAME - Fixed
# app_install_root=$(generate_var app_install_root APP_INSTALL_ROOT - Fixed
#-- Load Balancer --#

#-- Logging --#
lb_access_bucket_name=$(generate_var lb_access_bucket_name $LB_LOGS_BUCKET)

# -------------------------------------------------- #
echo "
#-- AWS --#
$aws_resource_identifier
$aws_resource_identifier_supershort
$aws_additional_tags

#-- ENV --#
$env_aws_secret

#-- EC2 --#
$aws_ec2_instance_create
$aws_ec2_ami_filter
$aws_ec2_ami_owner
$aws_ec2_ami_id
$aws_ec2_ami_update
$aws_ec2_iam_instance_profile
$aws_ec2_instance_type
$aws_ec2_instance_root_vol_size
$aws_ec2_instance_root_vol_preserve
$aws_ec2_security_group_name
$aws_ec2_create_keypair_sm
$aws_ec2_instance_public_ip
$aws_ec2_user_data_replace_on_change
$aws_ec2_additional_tags

#-- VPC --# 
$aws_vpc_create
$aws_vpc_name
$aws_vpc_cidr_block
$aws_vpc_public_subnets
$aws_vpc_private_subnets
$aws_vpc_availability_zones
$aws_vpc_id
$aws_vpc_subnet_id
$aws_vpc_additional_tags

#-- R53 --#
$aws_r53_enable
$aws_r53_domain_name
$aws_r53_sub_domain_name
$aws_r53_root_domain_deploy
$aws_r53_enable_cert
$aws_r53_cert_arn
$aws_r53_create_root_cert
$aws_r53_create_sub_cert
$aws_r53_additional_tags

#-- ELB --#
$aws_elb_security_group_name
$aws_elb_app_port
$aws_elb_app_protocol
$aws_elb_listen_port
$aws_elb_listen_protocol
$aws_elb_healthcheck
$lb_access_bucket_name
$aws_elb_additional_tags

#-- EFS --#
$aws_efs_enable
$aws_efs_create
$aws_efs_create_ha
$aws_efs_fs_id
$aws_efs_vpc_id
$aws_efs_subnet_ids
$aws_efs_security_group_name
$aws_efs_create_replica
$aws_efs_replication_destination
$aws_efs_enable_backup_policy
$aws_efs_transition_to_inactive
$aws_efs_mount_target
$aws_efs_ec2_mount_point
$aws_efs_additional_tags

#-- RDS --#
$aws_aurora_enable
$aws_aurora_engine
$aws_aurora_engine_version
$aws_aurora_database_group_family
$aws_aurora_instance_class
$aws_aurora_security_group_name
$aws_aurora_subnets
$aws_aurora_cluster_name
$aws_aurora_database_name
$aws_aurora_database_port
$aws_aurora_restore_snapshot
$aws_aurora_snapshot_name
$aws_aurora_snapshot_overwrite
$aws_aurora_database_protection
$aws_aurora_database_final_snapshot
$aws_aurora_additional_tags

#-- EKS --#
$aws_eks_create
$aws_eks_region
$aws_eks_security_group_name_master
$aws_eks_security_group_name_worker
$aws_eks_environment
$aws_eks_stackname
$aws_eks_cidr_block
$aws_eks_workstation_cidr
$aws_eks_availability_zones
$aws_eks_private_subnets
$aws_eks_public_subnets
$aws_eks_cluster_name
$aws_eks_cluster_log_types
$aws_eks_cluster_version
$aws_eks_instance_type
$aws_eks_instance_ami_id
$aws_eks_instance_user_data_file
$aws_eks_ec2_key_pair
$aws_eks_store_keypair_sm
$aws_eks_desired_capacity
$aws_eks_max_size
$aws_eks_min_size
$aws_eks_additional_tags

$docker_efs_mount_target
$docker_remove_orphans

#-- Application --#
$ops_repo_environment
$app_org_name
$app_repo_name
$app_branch_name
$app_install_root

" > "${GITHUB_ACTION_PATH}/operations/deployment/terraform/aws/terraform.tfvars"

# -------------------------------------------------- #
echo "
#-- AWS --#
$aws_resource_identifier
$aws_resource_identifier_supershort
$aws_additional_tags

#-- EKS --#
$aws_eks_create
$aws_eks_region
$aws_eks_security_group_name_master
$aws_eks_security_group_name_worker
$aws_eks_environment
$aws_eks_stackname
$aws_eks_cidr_block
$aws_eks_workstation_cidr
$aws_eks_availability_zones
$aws_eks_private_subnets
$aws_eks_public_subnets
$aws_eks_cluster_name
$aws_eks_cluster_log_types
$aws_eks_cluster_version
$aws_eks_instance_type
$aws_eks_instance_ami_id
$aws_eks_instance_user_data_file
$aws_eks_ec2_key_pair
$aws_eks_store_keypair_sm
$aws_eks_desired_capacity
$aws_eks_max_size
$aws_eks_min_size
$aws_eks_additional_tags

#-- Application --#
$ops_repo_environment
$app_org_name
$app_repo_name
$app_branch_name

" > "${GITHUB_ACTION_PATH}/operations/deployment/terraform/eks/terraform.tfvars"

# We might want to pass only the variables needed and not all of them. 

echo "Done with generate_vars_terraform.sh"