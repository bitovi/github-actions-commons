#!/bin/bash

set -e

echo "In generate_vars_terraform.sh"

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
aws_r53_sub_domain_name=
if [ -n "${AWS_R53_SUB_DOMAIN_NAME}" ]; then
  aws_r53_sub_domain_name="aws_r53_sub_domain_name = \"${AWS_R53_SUB_DOMAIN_NAME}\""
else
  aws_r53_sub_domain_name="aws_r53_sub_domain_name = \"${GITHUB_IDENTIFIER}\""
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
  aws_ec2_iam_instance_profile=$(generate_var aws_ec2_iam_instance_profile $AWS_EC2_IAM_INSTANCE_PROFILE)
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
if [[ $(alpha_only "$AWS_RDS_DB_ENABLE") == true ]]; then
  aws_rds_db_enable=$(generate_var aws_rds_db_enable $AWS_RDS_DB_ENABLE)
  aws_rds_db_proxy=$(generate_var aws_rds_db_proxy $AWS_RDS_DB_PROXY)
  aws_rds_db_identifier=$(generate_var aws_rds_db_identifier $AWS_RDS_DB_IDENTIFIER)
  aws_rds_db_name=$(generate_var aws_rds_db_name $AWS_RDS_DB_NAME)
  aws_rds_db_user=$(generate_var aws_rds_db_user $AWS_RDS_DB_USER)
  aws_rds_db_engine=$(generate_var aws_rds_db_engine $AWS_RDS_DB_ENGINE)
  aws_rds_db_engine_version=$(generate_var aws_rds_db_engine_version $AWS_RDS_DB_ENGINE_VERSION)
  aws_rds_db_ca_cert_identifier=$(generate_var aws_rds_db_ca_cert_identifier $AWS_RDS_DB_CA_CERT_IDENTIFIER)
  aws_rds_db_security_group_name=$(generate_var aws_rds_db_security_group_name $AWS_RDS_DB_SECURITY_GROUP_NAME)
  aws_rds_db_allowed_security_groups=$(generate_var aws_rds_db_allowed_security_groups $AWS_RDS_DB_ALLOWED_SECURITY_GROUPS)
  aws_rds_db_ingress_allow_all=$(generate_var aws_rds_db_ingress_allow_all $AWS_RDS_DB_INGRESS_ALLOW_ALL)
  aws_rds_db_publicly_accessible=$(generate_var aws_rds_db_publicly_accessible $AWS_RDS_DB_PUBLICLY_ACCESSIBLE)
  aws_rds_db_port=$(generate_var aws_rds_db_port $AWS_RDS_DB_PORT)
  aws_rds_db_subnets=$(generate_var aws_rds_db_subnets $AWS_RDS_DB_SUBNETS)
  aws_rds_db_allocated_storage=$(generate_var aws_rds_db_allocated_storage $AWS_RDS_DB_ALLOCATED_STORAGE)
  aws_rds_db_max_allocated_storage=$(generate_var aws_rds_db_max_allocated_storage $AWS_RDS_DB_MAX_ALLOCATED_STORAGE)
  aws_rds_db_storage_encrypted=$(generate_var aws_rds_db_storage_encrypted $AWS_RDS_DB_STORAGE_ENCRYPTED)
  aws_rds_db_storage_type=$(generate_var aws_rds_db_storage_type $AWS_RDS_DB_STORAGE_TYPE)
  aws_rds_db_kms_key_id=$(generate_var aws_rds_db_kms_key_id $AWS_RDS_DB_KMS_KEY_ID)
  aws_rds_db_instance_class=$(generate_var aws_rds_db_instance_class $AWS_RDS_DB_INSTANCE_CLASS)
  aws_rds_db_final_snapshot=$(generate_var aws_rds_db_final_snapshot $AWS_RDS_DB_FINAL_SNAPSHOT)
  aws_rds_db_restore_snapshot_identifier=$(generate_var aws_rds_db_restore_snapshot_identifier $AWS_RDS_DB_RESTORE_SNAPSHOT_IDENTIFIER)
  aws_rds_db_cloudwatch_logs_exports=$(generate_var aws_rds_db_cloudwatch_logs_exports $AWS_RDS_DB_CLOUDWATCH_LOGS_EXPORTS)
  aws_rds_db_multi_az=$(generate_var aws_rds_db_multi_az $AWS_RDS_DB_MULTI_AZ)
  aws_rds_db_maintenance_window=$(generate_var aws_rds_db_maintenance_window $AWS_RDS_DB_MAINTENANCE_WINDOWS)
  aws_rds_db_apply_immediately=$(generate_var aws_rds_db_apply_immediately $AWS_RDS_DB_APPLY_IMMEDIATELY)
  aws_rds_db_additional_tags=$(generate_var aws_rds_db_additional_tags $AWS_RDS_DB_ADDITIONAL_TAGS)
fi

#-- AURORA --#
if [[ $(alpha_only "$AWS_AURORA_ENABLE") == true ]]; then
  aws_aurora_enable=$(generate_var aws_aurora_enable $AWS_AURORA_ENABLE)
  aws_aurora_proxy=$(generate_var aws_aurora_proxy $AWS_AURORA_PROXY)
  aws_aurora_engine=$(generate_var aws_aurora_engine $AWS_AURORA_ENGINE)
  aws_aurora_engine_version=$(generate_var aws_aurora_engine_version $AWS_AURORA_ENGINE_VERSION)
  aws_aurora_database_group_family=$(generate_var aws_aurora_database_group_family $AWS_AURORA_DATABASE_GROUP_FAMILY)
  aws_aurora_instance_class=$(generate_var aws_aurora_instance_class $AWS_AURORA_INSTANCE_CLASS)
  aws_aurora_security_group_name=$(generate_var aws_aurora_security_group_name $AWS_AURORA_SECURITY_GROUP_NAME )
  aws_aurora_subnets=$(generate_var aws_aurora_subnets $AWS_AURORA_SUBNETS)
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

#-- DB PROXY --#
aws_db_proxy_enable=$(generate_var aws_db_proxy_enable $AWS_DB_PROXY_ENABLE)
aws_db_proxy_name=$(generate_var aws_db_proxy_name $AWS_DB_PROXY_NAME)
aws_db_proxy_database_id=$(generate_var aws_db_proxy_database_id $AWS_DB_PROXY_DATABASE_ID)
aws_db_proxy_cluster=$(generate_var aws_db_proxy_cluster $AWS_DB_PROXY_CLUSTER)
aws_db_proxy_secret_name=$(generate_var aws_db_proxy_secret_name $AWS_DB_PROXY_SECRET_NAME)
aws_db_proxy_client_password_auth_type=$(generate_var aws_db_proxy_client_password_auth_type $AWS_DB_PROXY_CLIENT_PASSWORD_AUTH_TYPE)
aws_db_proxy_tls=$(generate_var aws_db_proxy_tls $AWS_DB_PROXY_TLS)
aws_db_proxy_security_group_name=$(generate_var aws_db_proxy_security_group_name $AWS_DB_PROXY_SECURITY_GROUP_NAME)
aws_db_proxy_database_security_group_allow=$(generate_var aws_db_proxy_database_security_group_allow $AWS_DB_PROXY_DATABASE_SECURITY_GROUP_ALLOW)
aws_db_proxy_allowed_security_group=$(generate_var aws_db_proxy_allowed_security_group $AWS_DB_PROXY_ALLOWED_SECURITY_GROUP)
aws_db_proxy_allow_all_incoming=$(generate_var aws_db_proxy_allow_all_incoming $AWS_DB_PROXY_ALLOW_ALL_INCOMING)
aws_db_proxy_cloudwatch_enable=$(generate_var aws_db_proxy_cloudwatch_enable $AWS_DB_PROXY_CLOUDWATCH_ENABLE)
aws_db_proxy_cloudwatch_retention_days=$(generate_var aws_db_proxy_cloudwatch_retention_days $AWS_DB_PROXY_CLOUDWATCH_RETENTION_DAYS)
aws_db_proxy_additional_tags=$(generate_var aws_db_proxy_additional_tags $AWS_DB_PROXY_ADDITIONAL_TAGS)

#-- REDIS --# 
if [[ $(alpha_only "$AWS_REDIS_ENABLE") == true ]]; then
  aws_redis_enable=$(generate_var aws_redis_enable $AWS_REDIS_ENABLE)
  aws_redis_user=$(generate_var aws_redis_user $AWS_REDIS_USER)
  aws_redis_user_access_string=$(generate_var aws_redis_user_access_string $AWS_REDIS_USER_ACCESS_STRING)
  aws_redis_user_group_name=$(generate_var aws_redis_user_group_name $AWS_REDIS_USER_GROUP_NAME)
  aws_redis_security_group_name=$(generate_var aws_redis_security_group_name $AWS_REDIS_SECURITY_GROUP_NAME)
  aws_redis_ingress_allow_all=$(generate_var aws_redis_ingress_allow_all $AWS_REDIS_INGRESS_ALLOW_ALL)
  aws_redis_allowed_security_groups=$(generate_var aws_redis_allowed_security_groups $AWS_REDIS_ALLOWED_SECURITY_GROUPS)
  aws_redis_subnets=$(generate_var aws_redis_subnets $AWS_REDIS_SUBNETS)
  aws_redis_port=$(generate_var aws_redis_port $AWS_REDIS_PORT)
  aws_redis_at_rest_encryption=$(generate_var aws_redis_at_rest_encryption $AWS_REDIS_AT_REST_ENCRYPTION)
  aws_redis_in_transit_encryption=$(generate_var aws_redis_in_transit_encryption $AWS_REDIS_IN_TRANSIT_ENCRYPTION)
  aws_redis_replication_group_id=$(generate_var aws_redis_replication_group_id $AWS_REDIS_REPLICATION_GROUP_ID)
  aws_redis_node_type=$(generate_var aws_redis_node_type $AWS_REDIS_NODE_TYPE)
  aws_redis_num_cache_clusters=$(generate_var aws_redis_num_cache_clusters $AWS_REDIS_NUM_CACHE_CLUSTER)
  aws_redis_parameter_group_name=$(generate_var aws_redis_parameter_group_name $AWS_REDIS_PARAMETER_GROUP_NAME)
  aws_redis_num_node_groups=$(generate_var aws_redis_num_node_groups $AWS_REDIS_NUM_NODE_GROUPS)
  aws_redis_replicas_per_node_group=$(generate_var aws_redis_replicas_per_node_group $AWS_REDIS_REPLICAS_PER_NODE_GROUP)
  aws_redis_multi_az_enabled=$(generate_var aws_redis_multi_az_enabled $AWS_REDIS_MULTI_AZ_ENABLED)
  aws_redis_automatic_failover=$(generate_var aws_redis_automatic_failover $AWS_REDIS_AUTOMATIC_FAILOVER)
  aws_redis_apply_immediately=$(generate_var aws_redis_apply_immediately $AWS_REDIS_APPLY_IMMEDIATELY)
  aws_redis_auto_minor_upgrade=$(generate_var aws_redis_auto_minor_upgrade $AWS_REDIS_AUTO_MINOR_UPGRADE)
  aws_redis_maintenance_window=$(generate_var aws_redis_maintenance_window $AWS_REDIS_MAINTENANCE_WINDOW)
  aws_redis_snapshot_window=$(generate_var aws_redis_snapshot_window $AWS_REDIS_SNAPSHOT_WINDOW)
  aws_redis_final_snapshot=$(generate_var aws_redis_final_snapshot $AWS_REDIS_FINAL_SNAPSHOT)
  aws_redis_snapshot_restore_name=$(generate_var aws_redis_snapshot_restore_name $AWS_REDIS_SNAPSHOT_RESTORE_NAME)
  aws_redis_cloudwatch_enabled=$(generate_var aws_redis_cloudwatch_enabled $AWS_REDIS_CLOUDWATCH_ENABLED)
  aws_redis_cloudwatch_lg_name=$(generate_var aws_redis_cloudwatch_lg_name $AWS_REDIS_CLOUDWATCH_LG_NAME)
  aws_redis_cloudwatch_log_format=$(generate_var aws_redis_cloudwatch_log_format $AWS_REDIS_CLOUDWATCH_LOG_FORMAT)
  aws_redis_cloudwatch_log_type=$(generate_var aws_redis_cloudwatch_log_type $AWS_REDIS_CLOUDWATCH_LOG_TYPE)
  aws_redis_cloudwatch_retention_days=$(generate_var aws_redis_cloudwatch_retention_days $AWS_REDIS_CLOUDWATCH_RETENTION_DAYS)
  aws_redis_single_line_url_secret=$(generate_var aws_redis_single_line_url_secret $AWS_REDIS_SINGLE_LINE_URL_SECRET)
  aws_redis_additional_tags=$(generate_var aws_redis_additional_tags $AWS_REDIS_ADDITIONAL_TAGS)
fi

#-- ECS --#
if [[ $(alpha_only "$AWS_ECS_ENABLE") == true ]]; then
  aws_ecs_enable=$(generate_var aws_ecs_enable $AWS_ECS_ENABLE)
  aws_ecs_service_name=$(generate_var aws_ecs_service_name $AWS_ECS_SERVICE_NAME)
  aws_ecs_cluster_name=$(generate_var aws_ecs_cluster_name $AWS_ECS_CLUSTER_NAME)
  aws_ecs_service_launch_type=$(generate_var aws_ecs_service_launch_type $AWS_ECS_SERVICE_LAUNCH_TYPE)
  aws_ecs_task_type=$(generate_var aws_ecs_task_type $AWS_ECS_TASK_TYPE)
  aws_ecs_task_name=$(generate_var aws_ecs_task_name $AWS_ECS_TASK_NAME)
  aws_ecs_task_execution_role=$(generate_var aws_ecs_task_execution_role $AWS_ECS_TASK_EXECUTION_ROLE)
  aws_ecs_task_json_definition_file=$(generate_var aws_ecs_task_json_definition_file $AWS_ECS_TASK_JSON_DEFINITION_FILE)
  aws_ecs_task_network_mode=$(generate_var aws_ecs_task_network_mode $AWS_ECS_TASK_NETWORK_MODE)
  aws_ecs_task_cpu=$(generate_var aws_ecs_task_cpu $AWS_ECS_TASK_CPU)
  aws_ecs_task_mem=$(generate_var aws_ecs_task_mem $AWS_ECS_TASK_MEM)
  aws_ecs_container_cpu=$(generate_var aws_ecs_container_cpu $AWS_ECS_CONTAINER_CPU)
  aws_ecs_container_cpu=$(generate_var aws_ecs_container_mem $AWS_ECS_CONTAINER_MEM)
  aws_ecs_node_count=$(generate_var aws_ecs_node_count $AWS_ECS_NODE_COUNT)
  aws_ecs_app_image=$(generate_var aws_ecs_app_image $AWS_ECS_APP_IMAGE)
  aws_ecs_env_vars=$(generate_var aws_ecs_env_vars $AWS_ECS_ENV_VARS )
  aws_ecs_security_group_name=$(generate_var aws_ecs_security_group_name $AWS_ECS_SECURITY_GROUP_NAME)
  aws_ecs_assign_public_ip=$(generate_var aws_ecs_assign_public_ip $AWS_ECS_ASSIGN_PUBLIC_IP)
  aws_ecs_container_port=$(generate_var aws_ecs_container_port $AWS_ECS_CONTAINER_PORT)
  aws_ecs_lb_port=$(generate_var aws_ecs_lb_port $AWS_ECS_LB_PORT)
  aws_ecs_lb_redirect_enable=$(generate_var aws_ecs_lb_redirect_enable $AWS_ECS_LB_REDIRECT_ENABLE)
  aws_ecs_lb_container_path=$(generate_var aws_ecs_lb_container_path $AWS_ECS_LB_CONTAINER_PATH)
  aws_ecs_lb_ssl_policy=$(generate_var aws_ecs_lb_ssl_policy $AWS_ECS_LB_SSL_POLICY)
  aws_ecs_autoscaling_enable=$(generate_var aws_ecs_autoscaling_enable $AWS_ECS_AUTOSCALING_ENABLE)
  aws_ecs_autoscaling_max_nodes=$(generate_var aws_ecs_autoscaling_max_nodes $AWS_ECS_AUTOSCALING_MAX_NODES)
  aws_ecs_autoscaling_min_nodes=$(generate_var aws_ecs_autoscaling_min_nodes $AWS_ECS_AUTOSCALING_MIN_NODES)
  aws_ecs_autoscaling_max_mem=$(generate_var aws_ecs_autoscaling_max_mem $AWS_ECS_AUTOSCALING_MAX_MEM)
  aws_ecs_autoscaling_max_cpu=$(generate_var aws_ecs_autoscaling_max_cpu $AWS_ECS_AUTOSCALING_MIN_MEM)
  aws_ecs_cloudwatch_enable=$(generate_var aws_ecs_cloudwatch_enable $AWS_ECS_CLOUDWATCH_ENABLE)
  aws_ecs_cloudwatch_lg_name=$(generate_var aws_ecs_cloudwatch_lg_name $AWS_ECS_CLOUDWATCH_LG_NAME)
  aws_ecs_cloudwatch_skip_destroy=$(generate_var aws_ecs_cloudwatch_skip_destroy $AWS_ECS_CLOUDWATCH_SKIP_DESTROY)
  aws_ecs_cloudwatch_retention_days=$(generate_var aws_ecs_cloudwatch_retention_days $AWS_ECS_CLOUDWATCH_RETENTION_DAYS)
  aws_ecs_additional_tags=$(generate_var aws_ecs_additional_tags $AWS_ECS_ADDITIONAL_TAGS)
fi

#-- ECR --# 
if [[ $(alpha_only "$AWS_ECR_REPO_CREATE") == true ]]; then
  aws_ecr_repo_create=$(generate_var aws_ecr_repo_create $AWS_ECR_REPO_CREATE)
  aws_ecr_repo_type=$(generate_var aws_ecr_repo_type $AWS_ECR_REPO_TYPE)
  aws_ecr_repo_name=$(generate_var aws_ecr_repo_name $AWS_ECR_REPO_NAME)
  aws_ecr_repo_mutable=$(generate_var aws_ecr_repo_mutable $AWS_ECR_REPO_MUTABLE)
  aws_ecr_repo_encryption_type=$(generate_var aws_ecr_repo_encryption_type $AWS_ECR_REPO_ENCRYPTION_TYPE)
  aws_ecr_repo_encryption_key_arn=$(generate_var aws_ecr_repo_encryption_key_arn $AWS_ECR_REPO_ENCRYPTION_KEY_ARN)
  aws_ecr_repo_force_destroy=$(generate_var aws_ecr_repo_force_destroy $AWS_ECR_REPO_FORCE_DESTROY)
  aws_ecr_repo_image_scan=$(generate_var aws_ecr_repo_image_scan $AWS_ECR_REPO_IMAGE_SCAN)
  aws_ecr_registry_scan_rule=$(generate_var aws_ecr_registry_scan_rule $AWS_ECR_REGISTRY_SCAN_RULE)
  aws_ecr_registry_pull_through_cache_rules=$(generate_var aws_ecr_registry_pull_through_cache_rules $AWS_ECR_REGISTRY_PULL_THROUGH_CACHE_RULES)
  aws_ecr_registry_scan_config=$(generate_var aws_ecr_registry_scan_config $AWS_ECR_REGISTRY_SCAN_CONFIG)
  aws_ecr_registry_replication_rules_input=$(generate_var aws_ecr_registry_replication_rules_input $AWS_ECR_REGISTRY_REPLICATION_RULES_INPUT)
  aws_ecr_repo_policy_attach=$(generate_var aws_ecr_repo_policy_attach $AWS_ECR_REPO_POLICY_ATTACH)
  aws_ecr_repo_policy_create=$(generate_var aws_ecr_repo_policy_create $AWS_ECR_REPO_POLICY_CREATE)
  aws_ecr_repo_policy_input=$(generate_var aws_ecr_repo_policy_input $AWS_ECR_REPO_POLICY_INPUT)
  aws_ecr_repo_read_arn=$(generate_var aws_ecr_repo_read_arn $AWS_ECR_REPO_READ_ARN)
  aws_ecr_repo_write_arn=$(generate_var aws_ecr_repo_write_arn $AWS_ECR_REPO_WRITE_ARN)
  aws_ecr_repo_read_arn_lambda=$(generate_var aws_ecr_repo_read_arn_lambda $AWS_ECR_REPO_READ_ARN_LAMBDA)
  aws_ecr_lifecycle_policy_input=$(generate_var aws_ecr_lifecycle_policy_input $AWS_ECR_LIFECYCLE_POLICY_INPUT)
  aws_ecr_public_repo_catalog=$(generate_var aws_ecr_public_repo_catalog $AWS_ECR_PUBLIC_REPO_CATALOG)
  aws_ecr_registry_policy_input=$(generate_var aws_ecr_registry_policy_input $AWS_ECR_REGISTRY_POLICY_INPUT)
  aws_ecr_additional_tags=$(generate_var aws_ecr_additional_tags $AWS_ECR_ADDITIONAL_TAGS)
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
else
  ansible_ssh_to_private_ip=$(generate_var ansible_ssh_to_private_ip $ANSIBLE_SSH_TO_PRIVATE_IP)
  ansible_start_docker_timeout=$(generate_var ansible_start_docker_timeout $ANSIBLE_START_DOCKER_TIMEOUT)
fi

if [[ $(alpha_only "$DOCKER_INSTALL") == true ]]; then
  docker_install=$(generate_var docker_install $DOCKER_INSTALL)
  docker_remove_orphans=$(generate_var docker_remove_orphans $DOCKER_REMOVE_ORPHANS)
  docker_efs_mount_target=$(generate_var docker_efs_mount_target $DOCKER_EFS_MOUNT_TARGET)
  docker_cloudwatch_enable=$(generate_var docker_cloudwatch_enable $DOCKER_CLOUDWATCH_ENABLE)
  docker_cloudwatch_lg_name=$(generate_var docker_cloudwatch_lg_name $DOCKER_CLOUDWATCH_LG_NAME)
  docker_cloudwatch_skip_destroy=$(generate_var docker_cloudwatch_skip_destroy $DOCKER_CLOUDWATCH_SKIP_DESTROY)
  docker_cloudwatch_retention_days=$(generate_var docker_cloudwatch_retention_days $DOCKER_CLOUDWATCH_RETENTION_DAYS)
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
#-- ANSIBLE --#
$ansible_skip
$ansible_ssh_to_private_ip
$ansible_start_docker_timeout

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
$aws_ec2_port_list
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
$aws_elb_create
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
$aws_rds_db_enable
$aws_rds_db_proxy
$aws_rds_db_identifier
$aws_rds_db_name
$aws_rds_db_user
$aws_rds_db_engine
$aws_rds_db_engine_version
$aws_rds_db_ca_cert_identifier
$aws_rds_db_security_group_name
$aws_rds_db_allowed_security_groups
$aws_rds_db_ingress_allow_all
$aws_rds_db_publicly_accessible
$aws_rds_db_port
$aws_rds_db_subnets
$aws_rds_db_allocated_storage
$aws_rds_db_max_allocated_storage
$aws_rds_db_storage_encrypted
$aws_rds_db_storage_type
$aws_rds_db_kms_key_id
$aws_rds_db_instance_class
$aws_rds_db_final_snapshot
$aws_rds_db_restore_snapshot_identifier
$aws_rds_db_cloudwatch_logs_exports
$aws_rds_db_multi_az
$aws_rds_db_maintenance_window
$aws_rds_db_apply_immediately
$aws_rds_db_additional_tags

#-- AURORA --#
$aws_aurora_enable
$aws_aurora_proxy
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

#-- DB PROXY --#
$aws_db_proxy_enable
$aws_db_proxy_name
$aws_db_proxy_database_id
$aws_db_proxy_cluster
$aws_db_proxy_secret_name
$aws_db_proxy_client_password_auth_type
$aws_db_proxy_tls
$aws_db_proxy_security_group_name
$aws_db_proxy_database_security_group_allow
$aws_db_proxy_allowed_security_group
$aws_db_proxy_allow_all_incoming
$aws_db_proxy_cloudwatch_enable
$aws_db_proxy_cloudwatch_retention_days
$aws_db_proxy_additional_tags

#-- REDIS --#
$aws_redis_enable
$aws_redis_user
$aws_redis_user_access_string
$aws_redis_user_group_name
$aws_redis_security_group_name
$aws_redis_ingress_allow_all
$aws_redis_allowed_security_groups
$aws_redis_subnets
$aws_redis_port
$aws_redis_at_rest_encryption
$aws_redis_in_transit_encryption
$aws_redis_replication_group_id
$aws_redis_node_type
$aws_redis_num_cache_clusters
$aws_redis_parameter_group_name
$aws_redis_num_node_groups
$aws_redis_replicas_per_node_group
$aws_redis_multi_az_enabled
$aws_redis_automatic_failover
$aws_redis_apply_immediately
$aws_redis_auto_minor_upgrade
$aws_redis_maintenance_window
$aws_redis_snapshot_window
$aws_redis_final_snapshot
$aws_redis_snapshot_restore_name
$aws_redis_cloudwatch_enabled
$aws_redis_cloudwatch_lg_name
$aws_redis_cloudwatch_log_format
$aws_redis_cloudwatch_log_type
$aws_redis_cloudwatch_retention_days
$aws_redis_single_line_url_secret
$aws_redis_additional_tags

#-- ECS --#
$aws_ecs_enable
$aws_ecs_service_name
$aws_ecs_cluster_name
$aws_ecs_service_launch_type
$aws_ecs_task_type
$aws_ecs_task_name
$aws_ecs_task_execution_role
$aws_ecs_task_json_definition_file
$aws_ecs_task_network_mode
$aws_ecs_task_cpu
$aws_ecs_task_mem
$aws_ecs_container_cpu
$aws_ecs_container_mem
$aws_ecs_node_count
$aws_ecs_app_image
$aws_ecs_env_vars
$aws_ecs_security_group_name
$aws_ecs_assign_public_ip
$aws_ecs_container_port
$aws_ecs_lb_port
$aws_ecs_lb_redirect_enable
$aws_ecs_lb_container_path
$aws_ecs_lb_ssl_policy
$aws_ecs_autoscaling_enable
$aws_ecs_autoscaling_max_nodes
$aws_ecs_autoscaling_min_nodes
$aws_ecs_autoscaling_max_mem
$aws_ecs_autoscaling_max_cpu
$aws_ecs_cloudwatch_enable
$aws_ecs_cloudwatch_lg_name
$aws_ecs_cloudwatch_skip_destroy
$aws_ecs_cloudwatch_retention_days
$aws_ecs_additional_tags

#-- ECR --#
$aws_ecr_repo_create
$aws_ecr_repo_type
$aws_ecr_repo_name
$aws_ecr_repo_mutable
$aws_ecr_repo_encryption_type
$aws_ecr_repo_encryption_key_arn
$aws_ecr_repo_force_destroy
$aws_ecr_repo_image_scan
$aws_ecr_registry_scan_rule
$aws_ecr_registry_pull_through_cache_rules
$aws_ecr_registry_scan_config
$aws_ecr_registry_replication_rules_input
$aws_ecr_repo_policy_attach
$aws_ecr_repo_policy_create
$aws_ecr_repo_policy_input
$aws_ecr_repo_read_arn
$aws_ecr_repo_write_arn
$aws_ecr_repo_read_arn_lambda
$aws_ecr_lifecycle_policy_input
$aws_ecr_public_repo_catalog
$aws_ecr_registry_policy_input
$aws_ecr_additional_tags

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
$docker_cloudwatch_enable
$docker_cloudwatch_lg_name
$docker_cloudwatch_skip_destroy
$docker_cloudwatch_retention_days

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

#-- ECR --#
$aws_ecr_repo_create
$aws_ecr_repo_type
$aws_ecr_repo_name
$aws_ecr_repo_mutable
$aws_ecr_repo_encryption_type
$aws_ecr_repo_encryption_key_arn
$aws_ecr_repo_force_destroy
$aws_ecr_repo_image_scan
$aws_ecr_registry_scan_rule
$aws_ecr_registry_pull_through_cache_rules
$aws_ecr_registry_scan_config
$aws_ecr_registry_replication_rules_input
$aws_ecr_repo_policy_attach
$aws_ecr_repo_policy_create
$aws_ecr_repo_policy_input
$aws_ecr_repo_read_arn
$aws_ecr_repo_write_arn
$aws_ecr_repo_read_arn_lambda
$aws_ecr_lifecycle_policy_input
$aws_ecr_public_repo_catalog
$aws_ecr_registry_policy_input
$aws_ecr_additional_tags

#-- Application --#
$ops_repo_environment
$app_org_name
$app_repo_name
$app_branch_name

" > "${GITHUB_ACTION_PATH}/operations/deployment/terraform/ecr/terraform.tfvars"


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