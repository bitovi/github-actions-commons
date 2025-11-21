# Ansible vars
variable "ansible_skip" {
  type        = bool
  description = "Skip Ansible inventory file generation."
  default     = false
}

variable "ansible_ssh_to_private_ip" {
  type        = bool
  description = "Make Ansible connect to the private IP of the instance. Only usefull if using a hosted runner in the same network."
  default     = false
}

variable "ansible_start_docker_timeout" {
  type        = string
  description = "Ammount of time in seconds it takes Ansible to mark as failed the startup of docker."
  default     = "300"
}

# AWS Specific

variable "aws_resource_identifier" {
  type        = string
  description = "Identifier to use for AWS resources (defaults to GITHUB_ORG-GITHUB_REPO-GITHUB_BRANCH)"
  default     = ""
}

variable "aws_resource_identifier_supershort" {
  type        = string
  description = "Identifier to use for AWS resources (defaults to GITHUB_ORG-GITHUB_REPO-GITHUB_BRANCH) shortened to 30 chars"
  default     = ""
}

variable "aws_additional_tags" {
  type        = string
  description = "A list of strings that will be added to created resources"
  default     = "{}"
}

# ENV Files

variable "env_aws_secret" {
  type        = string
  description = "Secret name to pull env variables from AWS Secret Manager"
  default     = ""
}

# EC2 Instance

variable "aws_ec2_instance_create" {
  type        = bool
  description = "Enable EC2 Instance creation."
  default     = false
}

variable "aws_ec2_ami_id" {
  type        = string
  description = "AWS AMI ID image to use for deployment"
  default     = ""
}

variable "aws_ec2_ami_update" {
  type        = bool
  description = "Recreates the EC2 instance if there is a newer version of the AMI"
  default     = false
}

variable "aws_ec2_ami_filter" {
  type        = string
  description = "AWS AMI Filter string. Will be used to lookup for lates image based on the string."
  default     = "ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"
}

variable "aws_ec2_ami_owner" {
  type        = string
  description = "Owner of AWS AMI image. This ensures the provider is the one we are looking for."
  default     = "099720109477"
}

variable "aws_ec2_iam_instance_profile" {
  type        = string
  description = "IAM role for the ec2 instance"
  default     = ""
}

variable "aws_ec2_instance_type" {
  type        = string
  description = "Instance type for the EC2 instance"
  default     = "t2.small"
}

variable "aws_ec2_instance_root_vol_size" {
  type        = string
  description = "Instance type for the EC2 instance"
  default     = "8"
}

variable "aws_ec2_instance_root_vol_preserve" {
  type        = bool
  description = "Set this to true to avoid deletion of root volume on termination."
  default     = false
}

variable "aws_ec2_security_group_name" {
  type        = string
  description = "Name of the security group to use"
  default     = ""
}

variable "aws_ec2_create_keypair_sm" {
  type        = bool
  description = "y/n create sm entry for ec2 keypair"
  default     = false
}

variable "aws_ec2_instance_public_ip" {
  type        = bool
  description = "Attach public IP to the EC2 instance"
  default     = false
}

variable "aws_ec2_port_list" {
  type        = string
  description = "List of ports to be enabled as an ingress rule in the EC2 SG, in a [xx,yy] format - Not the ELB"
  default     = ""
}

variable "aws_ec2_user_data_replace_on_change"  {
  type        = bool
  description = "Forces destruction of EC2 instance"
  default     = true
}

variable "aws_ec2_additional_tags" {
  type        = string
  description = "A list of strings that will be added to created resources"
  default     = "{}"
}

## AWS VPC
variable "aws_vpc_create" {
  type        = bool
  description = "Toggle VPC creation"
  default     = false
}

variable "aws_vpc_name" {
  type = string
  description = "Name for the aws vpc"
  default = ""
}

variable "aws_vpc_id" {
  type = string
  description = "aws vpc id"
  default = ""
}

variable "aws_vpc_subnet_id" {
  type = string
  description = "aws vpc subnet id"
  default = ""
}

variable "aws_vpc_cidr_block" {
  type        = string
  description = "CIDR of the VPC"
  default     = "10.10.0.0/16"
}

variable "aws_vpc_public_subnets" {
  type        = string
  description = "A list of public subnets"
  default     = "10.10.110.0/24"
}

variable "aws_vpc_private_subnets" {
  type        = string
  description = "A list of private subnets"
  default     = ""
}

variable "aws_vpc_availability_zones" {
  type        = string
  description = "A list of availability zones."
  default     = ""
}

variable "aws_vpc_additional_tags" {
  type        = string
  description = "A list of strings that will be added to created resources"
  default     = "{}"
}

variable "aws_vpc_enable_nat_gateway" {
  type        = bool
  description = "Enables NAT gateway"
  default     = false
}

variable "aws_vpc_single_nat_gateway" {
  type        = bool
  description = "Creates only one NAT gateway"
  default     = false
}

variable "aws_vpc_external_nat_ip_ids" {
  type        = string
  description = "Comma separated list of IP IDS to reuse in the NAT gateways"
  default     = ""
}

# AWS Route53 Domains abd Certificates
variable "aws_r53_enable" {
  type        = bool
  description = "Enable AWS R53 management."
  default     = false
}

variable "aws_r53_domain_name" {
  type        = string
  description = "root domain name without any subdomains"
  default     = ""
}

variable "aws_r53_sub_domain_name" {
  type        = string
  description = "Subdomain name for DNS record"
  default     = ""
}


variable "aws_r53_root_domain_deploy" {
  type        = bool
  description = "deploy to root domain"
  default     = false
}

variable "aws_r53_enable_cert" {
  type        = bool
  description = "Enable AWS Certificate management."
  default     = false
}

variable "aws_r53_cert_arn" {
  type        = string
  description = "Certificate ARN to use"
  default     = ""
}

variable "aws_r53_create_root_cert" {
  type        = bool
  description = "deploy to root domain"
  default     = false
}

variable "aws_r53_create_sub_cert" {
  type        = bool
  description = "deploy to root domain"
  default     = false
}

variable "aws_r53_additional_tags" {
  type        = string
  description = "A list of strings that will be added to created resources"
  default     = "{}"
}

# AWS ELB
variable "aws_elb_create" {
  type        = bool
  description = "Global toggle for ELB creation"
  default     = false
}

variable "aws_elb_security_group_name" {
  type        = string
  description = "Name of the security group to use"
  default     = ""
}

variable "aws_elb_app_port" {
  type        = string
  description = "app port"
  default     = ""
}

variable "aws_elb_app_protocol" {
  type        = string
  description = "Protocol to enable. Could be HTTP, HTTPS, TCP or SSL."
  default     = "tcp"
}

variable "aws_elb_listen_port" {
  type        = string
  description = "Load balancer listening port. Defaults to 80 if NO FQDN provided, 443 if FQDN provided"
  default     = ""
}

variable "aws_elb_listen_protocol" {
  type        = string
  description = "Protocol to enable. Could be HTTP, HTTPS, TCP or SSL. Defaults to TCP if NO FQDN provided, SSL if FQDN provided"
  default     = ""
}

variable "aws_elb_healthcheck" {
  type        = string
  description = "Load balancer health check string. Defaults to TCP:22"
  default     = "TCP:22"
}

variable "aws_elb_access_log_bucket_name" {
  type        = string
  description = "S3 bucket name to store the ELB access logs."
  default     = ""
}

variable "aws_elb_access_log_expire" {
  type        = string
  description = "Delete the access logs after this amount of days. Defaults to 90."
  default     = "90"
}

variable "aws_elb_additional_tags" {
  type        = string
  description = "A list of strings that will be added to created resources"
  default     = "{}"
}

# AWS LB

# AWS WAF
variable "aws_waf_enable" {
  type        = bool
  description = "Enable WAF for load balancer"
  default     = false
}

variable "aws_waf_logging_enable" {
  type        = bool
  description = "Enable WAF logging to CloudWatch"
  default     = false
}

variable "aws_waf_log_retention_days" {
  type        = number
  description = "CloudWatch log retention period for WAF logs"
  default     = 30
}

variable "aws_waf_additional_tags" {
  type        = string
  description = "A list of strings that will be added to created resources"
  default     = "{}"
}

variable "aws_waf_rule_rate_limit" {
  type        = string
  description = "Rate limit for WAF rules"
  default     = "2000"
}

variable "aws_waf_rule_managed_rules" {
  type        = bool
  description = "Enable common managed rule groups to use"
  default     = false
}

variable "aws_waf_rule_managed_bad_inputs" {
  type        = bool
  description = "Enable managed rule for bad inputs"
  default     = false
}

variable "aws_waf_rule_ip_reputation" {
  type        = bool
  description = "Enable managed rule for IP reputation"
  default     = false
}

variable "aws_waf_rule_anonymous_ip" {
  type        = bool
  description = "Enable managed rule for anonymous IP"
  default     = false
}

variable "aws_waf_rule_bot_control" {
  type        = bool
  description = "Enable managed rule for bot control (costs extra)"
  default     = false
}

variable "aws_waf_rule_geo_block_countries" {
  type        = string
  description = "Comma separated list of countries to block"
  default     = ""
}

variable "aws_waf_rule_geo_allow_only_countries" {
  type        = string
  description = "Comma separated list of countries to allow"
  default     = ""
}

variable "aws_waf_rule_sqli" {
  type        = bool
  description = "Enable managed rule for SQL injection"
  default     = false
}

variable "aws_waf_rule_linux" {
  type        = bool
  description = "Enable managed rule for Linux"
  default     = false
}

variable "aws_waf_rule_unix" {
  type        = bool
  description = "Enable managed rule for Unix"
  default     = false
}

variable "aws_waf_rule_admin_protection" {
  type        = bool
  description = "Enable managed rule for admin protection"
  default     = false
}

variable "aws_waf_rule_user_arn" {
  type        = string
  description = "ARN of the user rule"
  default     = ""
}

# AWS EFS

### This variable is hidden for the end user. Is built in deploy.sh based on the next 3 variables. 
variable "aws_efs_enable" {
  type        = bool
  description = "Global toggle for EFS creation/mounting or not"
  default     = false
}

variable "aws_efs_create" {
  type        = bool
  description = "Toggle to indicate whether to create and EFS and mount it to the ec2 as a part of the provisioning. Note: The EFS will be managed by the stack and will be destroyed along with the stack."
  default     = false
}

variable "aws_efs_fs_id" {
  type        = string
  description = "ID of existing EFS"
  default     = null
}

variable "aws_efs_create_mount_target" {
  type        = bool
  description = "Toggle to indicate whether we should create a mount target for the EFS volume."
  default     = true
}

variable "aws_efs_create_ha" {
  type        = bool
  description = "Toggle to indicate whether the EFS resource should be highly available (mount points in all available zones within region)."
  default     = false
}

variable "aws_efs_vol_encrypted" {
  type        = bool
  description = "Toggle encryption of the EFS volume."
  default     = true
}

variable "aws_efs_kms_key_id" {
  type        = string
  description = "The ARN for the KMS encryption key."
  default     = ""
}

variable "aws_efs_performance_mode" {
  type        = string
  description = "Toggle perfomance mode. Options are: generalPurpose or maxIO."
  default     = null
}

variable "aws_efs_throughput_mode" {
  type        = string
  description = "Throughput mode for the file system. Defaults to bursting. Valid values: bursting, provisioned, or elastic. When using provisioned, also set provisioned_throughput_in_mibps."
  default     = null
}

variable "aws_efs_throughput_speed" {
  type        = string
  description = "The throughput, measured in MiB/s, that you want to provision for the file system. Only applicable with throughput_mode set to provisioned."
  default     = null
}

variable "aws_efs_security_group_name" {
  type        = string
  description = "Name of the security group to use"
  default     = ""
}

variable "aws_efs_allowed_security_groups" {
  type        = string
  description = "Comma separated list of security groups to add to the EFS SG"
  default     = null
}

variable "aws_efs_ingress_allow_all" {
  type        = bool
  description = "Allow incoming traffic from 0.0.0.0/0."
  default     = true
}

variable "aws_efs_create_replica" {
  type        = bool
  description = "Toggle to indiciate whether a read-only replica should be created for the EFS primary file system"
  default     = false
}

variable "aws_efs_replication_destination" {
  type        = string
  description = "AWS Region to target for replication"
  default     = ""
}

variable "aws_efs_enable_backup_policy" {
  type        = bool
  description = "Toggle to indiciate whether the EFS should have a backup policy, default is `false`"
  default     = false
}

variable "aws_efs_transition_to_inactive" {
  type        = string
  description = "https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/efs_file_system#transition_to_ia"
  default     = "AFTER_30_DAYS"
}

variable "aws_efs_mount_target" {
  type        = string
  description = "Directory path in efs to mount to"
  default     = null
}

variable "aws_efs_ec2_mount_point" {
  type        = string
  description = "Directory path in application env to mount directory"
  default     = "data"
}

variable "aws_efs_additional_tags" {
  type        = string
  description = "A list of strings that will be added to created resources"
  default     = "{}"
}

# AWS RDS

variable "aws_rds_db_enable" {
  type        = bool
  description = "DB Toggle"
  default     = false
}

variable "aws_rds_db_proxy" {
  type        = bool
  description = "DB Proxy Toggle"
  default     = false
}

variable "aws_rds_db_identifier" {
  type        = string
  description = "Database identifier that will appear in the AWS Console. Defaults to aws_resource_identifier if none set."
  default     = ""
}

variable "aws_rds_db_name" {
  type        = string
  description = "The name of the database to create when the DB instance is created. If this parameter is not specified, no database is created in the DB instance."
  default     = null
}

variable "aws_rds_db_user" {
  type        = string
  description = "Database username"
  default     = "dbuser"
}

variable "aws_rds_db_engine" {
  type        = string
  description = "Which Database engine to use."
  default     = "postgres"
}

variable "aws_rds_db_engine_version" {
  type        = string
  description = "Which Database engine to use."
  default     = null
}

variable "aws_rds_db_ca_cert_identifier" {
  type        = string
  description = "Certificate to use with the database"
  default     = "rds-ca-ecc384-g1"
}

variable "aws_rds_db_security_group_name" {
  type        = string
  description = "The name of the database security group. Defaults to SG for aws_resource_identifier - RDS"
  default     = null
}

variable "aws_rds_db_allowed_security_groups" {
  type        = string
  description = "Comma separated list of security groups to add to the DB SG"
  default     = null
}

variable "aws_rds_db_ingress_allow_all" {
  type        = bool
  description = "Allow incoming traffic from 0.0.0.0/0."
  default     = true
}

variable "aws_rds_db_publicly_accessible" {
  type        = bool
  description = "Allow the database to be publicly accessible."
  default     = false
}

variable "aws_rds_db_port" {
  type        = string
  description = "Port where the DB listens to."
  default     = null
}

variable "aws_rds_db_subnets" {
  type        = string
  description = "aws_rds_db_subnets"
  default     = null
}

variable "aws_rds_db_allocated_storage" {
  type        = string
  description = "Storage size."
  default     = "10"
}

variable "aws_rds_db_max_allocated_storage" {
  type        = string
  description = "Max Storage size. 0 to disable autoscaling"
  default     = "0"
}

variable "aws_rds_db_storage_encrypted" {
  type        = bool
  description = "Toogle storage encryption. Defatuls to false."
  default     = false
}

variable "aws_rds_db_storage_type" {
  type        = string
  description = "Storage type. Like gp2 / gp3. Defaults to gp2."
  default     = ""
}

variable "aws_rds_db_kms_key_id" {
  type        = string
  description = "The ARN for the KMS encryption key."
  default     = ""
}

variable "aws_rds_db_instance_class" {
  type        = string
  description = "Server size"
  default     = "db.t3.micro"
}

variable "aws_rds_db_final_snapshot" {
  type        = string
  description = "Generates a snapshot of the database before deletion. None if no name is provided."
  default     = ""
}

variable "aws_rds_db_restore_snapshot_identifier" {
  type        = string
  description = "Name of the snapshot to restore the database from."
  default     = ""
}

variable "aws_rds_db_cloudwatch_logs_exports" {
  type        = string
  description = "logs exports"
  default     = "postgresql"
}

variable "aws_rds_db_multi_az" {
  type        = bool
  description = "Specifies if the RDS instance is multi-AZ"
  default     = false
}

variable "aws_rds_db_maintenance_window" {
  type        = string
  description = "The window to perform maintenance in. Eg: Mon:00:00-Mon:03:00 "
  default     = ""
}

variable "aws_rds_db_apply_immediately" {
  type        = bool
  description = "Specifies whether any database modifications are applied immediately, or during the next maintenance window"
  default     = false
}

variable "aws_rds_db_performance_insights_enable" {
  type        = bool
  description = "Specifies whether to enable Performance Insights for the DB instance."
  default     = false
}

variable "aws_rds_db_performance_insights_retention" {
  type        = string
  description = "The amount of time, in days, to retain Performance Insights data. Valid values are 7 or 731 (2 years)."
  default     = "7"
}

variable "aws_rds_db_performance_insights_kms_key_id" {
  type        = string
  description = "The ARN for the KMS key to encrypt performance insights data."
  default     = ""
}

variable "aws_rds_db_monitoring_interval" {
  type        = string
  description = "The interval, in seconds, between points when Enhanced Monitoring metrics are collected for the DB instance. To disable collecting specify 0."
  default     = "0"
}

variable "aws_rds_db_monitoring_role_arn" {
  type        = string
  description = "The ARN of the IAM role that provides access to the Enhanced Monitoring metrics."
  default     = ""
}

variable "aws_rds_db_insights_mode" {
  type        = string
  description = "The mode for Performance Insights."
  default     = "standard"
}

variable "aws_rds_db_allow_major_version_upgrade" {
  type        = bool
  description = "Indicates that major version upgrades are allowed."
  default     = false
}

variable "aws_rds_db_auto_minor_version_upgrade" {
  type        = bool
  description = "Indicates that minor version upgrades are allowed."
  default     = true
}

variable "aws_rds_db_backup_retention_period" {
  type        = string
  description = "The number of days to retain backups for. Must be between 0 (disabled) and 35."
  default     = 0
}

variable "aws_rds_db_backup_window" {
  type        = string
  description = "The window during which backups are taken."
  default     = ""
}

variable "aws_rds_db_copy_tags_to_snapshot" {
  type        = bool
  description = "Indicates whether to copy tags to snapshots."
  default     = false
}

variable "aws_rds_db_additional_tags" {
  type        = string
  description = "A list of strings that will be added to created resources"
  default     = "{}"
}

# AWS Aurora

variable "aws_aurora_enable" {
  type        = bool
  description = "Toggles deployment of an Aurora database"
  default     = false
}

variable "aws_aurora_proxy" {
  type        = bool
  description = "Aurora DB Proxy Toggle"
  default     = false
}

variable "aws_aurora_cluster_name" {
  type        = string
  description = "The name of the cluster. will be created if it does not exist."
  default     = ""
}

variable "aws_aurora_engine" {
  type        = string
  description = "The engine to use for postgres.  Defaults to `aurora-postgresql`.  For more details, see: https://aws.amazon.com/rds/, https://registry.terraform.io/modules/terraform-aws-modules/rds-aurora/aws/latest?tab=inputs"
  default     = "aurora-postgresql"
}

variable "aws_aurora_engine_version" {
  type        = string
  description = "The version of the engine to use for postgres."
  default     = ""
}

variable "aws_aurora_engine_mode" {
  type        = string
  description = "Database engine mode. global, multimaster, parallelquey, provisioned, serverless."
  default     = ""
}

variable "aws_aurora_availability_zones" {
  type        = string
  description = "List of availability zones for the DB cluster storage where DB cluster instances can be created."
  default     = ""
}

variable "aws_aurora_cluster_apply_immediately" {
  type        = bool
  description = "Apply changes immediately to the cluster. If not, will be done in next maintenance window."
  default     = false
}

# Storage 
variable "aws_aurora_allocated_storage" {
  type        = string
  description = "Amount of storage in gigabytes. Required for multi-az cluster."
  default     = ""
}

variable "aws_aurora_storage_encrypted" {
  type        = bool
  description = "Toggles whether the DB cluster is encrypted. Defaults to true."
  default     = true
}

variable "aws_aurora_kms_key_id" {
  type        = string
  description = "KMS Key ID to use with the cluster encrypted storage"
  default     = ""
}

variable "aws_aurora_storage_type" {
  type        = string
  description = "Define type of storage to use. Required for multi-az cluster."
  default     = ""
}

variable "aws_aurora_storage_iops" {
  type        = string
  description = "iops for storage"
  default     = ""
}

# DB Details
variable "aws_aurora_database_name" {
  type        = string
  description = "The name of the database. will be created if it does not exist."
  default     = "aurora"
}

variable "aws_aurora_master_username" {
  type        = string
  description = "Master username"
  default     = "aurora"
}

variable "aws_aurora_database_group_family" {
  type        = string
  description = "The family of the DB parameter group. See https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/AuroraMySQL.Reference.html https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/AuroraPostgreSQL.Reference.html"
  default     = ""
}

variable "aws_aurora_iam_auth_enabled" {
  type        = bool
  description = "Toggles IAM Authentication"
  default     = false
}

variable "aws_aurora_iam_roles" {
  type        = string
  description = "Define the ARN list of allowed roles"
  default     = ""
}

variable "aws_aurora_cluster_db_instance_class" {
  type        = string
  description = "To create a Multi-AZ RDS cluster, you must additionally specify the engine, storage_type, allocated_storage, iops and aws_aurora_db_cluster_instance_class attributes."
  default     = ""
}

variable "aws_aurora_security_group_name" {
  type        = string
  description = "Name of the security group to use for postgres"
  default     = ""
}

variable "aws_aurora_ingress_allow_all" {
  type        = bool
  description = "Allow access from 0.0.0.0/0 in the same VPC"
  default     = true
}

variable "aws_aurora_allowed_security_groups" {
  type        = string
  description = "Name of the security groups to access Aurora"
  default     = ""
}

variable "aws_aurora_subnets" {
  type        = string
  description = "The list of subnet ids to use for postgres. For more details, see: https://registry.terraform.io/modules/terraform-aws-modules/rds-aurora/aws/latest?tab=inputs"
  default     = ""
}

variable "aws_aurora_database_port" {
  type        = string
  description = "Database port"
  default     = "5432"
}

variable "aws_aurora_db_publicly_accessible" {
  type        = bool
  description = "Make database publicly accessible"
  default     = false
}

# Backup & maint
variable "aws_aurora_cloudwatch_enable" {
  type        = bool
  description = "Toggles cloudwatch"
  default     = true
}

variable "aws_aurora_cloudwatch_log_type" {
  type        = string
  description = "Comma separated list of log types to include in cloudwatch. If none defined, will use [postgresql] or  [audit,error,general,slowquery]. "
  default     = ""
}

variable "aws_aurora_cloudwatch_retention_days" {
  type        = string
  description = "Days to store cloudwatch logs. Defaults to 7."
  default     = "7"
}

variable "aws_aurora_backtrack_window" {
  type        = string
  description = "Target backtrack window, in seconds. Only available for aurora and aurora-mysql engines currently. 0 to disable (default)."
  default     = "0"
}

variable "aws_aurora_backup_retention_period" {
  type        = string
  description = "Days to retain backups for. Defaults to 5"
  default     = "5"
}

variable "aws_aurora_backup_window" {
  type        = string
  description = "Daily time range during which the backups happen"
  default     = ""
}

variable "aws_aurora_maintenance_window" {
  type        = string
  description = "Maintenance window"
  default     = ""
}

variable "aws_aurora_database_final_snapshot" {
  type        = string
  description = "Generates a snapshot of the database before deletion."
  default     = ""
}

variable "aws_aurora_deletion_protection" {
  type        = bool
  description = "Protects the database from deletion."
  default     = false
}

variable "aws_aurora_delete_auto_backups" {
  type        = bool
  description = "Specifies whether to remove automated backups immediately after the DB cluster is deleted. Default is true."
  default     = true
}

variable "aws_aurora_restore_snapshot_id" {
  type        = string
  description = "Restore an initial snapshot of the DB."
  default     = ""
}

variable "aws_aurora_restore_to_point_in_time" {
  type        = map(string)
  description = "Restore database to a point in time. Will require a map of strings."
  default     = {}
}

variable "aws_aurora_snapshot_name" {
  type        = string
  description = "Takes a snapshot of the DB."
  default     = ""
}

variable "aws_aurora_snapshot_overwrite" {
  type        = bool
  description = "Overwrites snapshot if same name is set. Defaults to false."
  default     = false
}

# DB Parameters
variable "aws_aurora_db_instances_count" {
  type        = string
  description = "Amount of instances to create"
  default     = "1"
}

variable "aws_aurora_db_instance_class" {
  type        = string
  description = "Database instance size"
  default     = "db.r6g.large"
}

variable "aws_aurora_db_apply_immediately" {
  type        = bool
  description = "Specifies whether any modifications are applied immediately, or during the next maintenance window. Default is false."
  default     = false
}

variable "aws_aurora_db_ca_cert_identifier" {
  type        = string
  description = "Certificate to use with the database"
  default     = "rds-ca-ecc384-g1"
}

variable "aws_aurora_db_maintenance_window" {
  type        = string
  description = "Maintenance window"
  default     = ""
}

variable "aws_aurora_performance_insights_enable" {
  type        = bool
  description = "Specifies whether to enable Performance Insights for the DB instance."
  default     = false
}

variable "aws_aurora_performance_insights_retention" {
  type        = string
  description = "The amount of time, in days, to retain Performance Insights data. Valid values are 7 or 731 (2 years)."
  default     = "7"
}

variable "aws_aurora_performance_insights_kms_key_id" {
  type        = string
  description = "The ARN for the KMS key to encrypt performance insights data."
  default     = ""
}

variable "aws_aurora_additional_tags" {
  type        = string
  description = "A list of strings that will be added to created resources"
  default     = "{}"
}

# RDS Proxy

variable "aws_db_proxy_enable" {
  type        = bool
  description = "deploy a proxy for the database"
  default     = false
}

variable "aws_db_proxy_name" {
  type        = string
  description = "DB Proxy name"
  default     = ""
}

variable "aws_db_proxy_database_id" {
  type        = string
  description = "Database ID to create proxy for"
  default     = ""
}

variable "aws_db_proxy_cluster" {
  type        = bool
  description = "Define if Database is a cluster or not"
  default     = false
}

variable "aws_db_proxy_secret_name" {
  type        = string
  description = "Name of the secret containing DB parameters to connect to"
  default     = ""
}

variable "aws_db_proxy_client_password_auth_type" {
  type        = string
  description = "Auth type to use, will use the following, depending on DB the family. MYSQL_NATIVE_PASSWORD, POSTGRES_SCRAM_SHA_256, and SQL_SERVER_AUTHENTICATION"
  default     = ""
}

variable "aws_db_proxy_tls" {
  type        = bool
  description = "Toogle TLS enforcement for connection"
  default     = "true"
}

variable "aws_db_proxy_security_group_name" {
  type        = string
  description = "Name for the proxy security group. Default to aws_resource_identifier if none."
  default     = ""
}

variable "aws_db_proxy_database_security_group_allow" {
  type        = bool
  description = "Will add an incoming rule from every security group associated with the DB"
  default     = false
}

variable "aws_db_proxy_allowed_security_group" {
  type        = string
  description = "Comma separated list of SG Ids to add."
  default     = ""
}

variable "aws_db_proxy_allow_all_incoming" {
  type        = bool
  description = "Allow all incoming traffic to the DB Proxy. Mind that the proxy is only available from the internal network except manually exposed."
  default     = "false"
}

variable "aws_db_proxy_cloudwatch_enable" {
  type        = bool
  description = "Toggle Cloudwatch logs. Will be stored in /aws/rds/proxy/rds_proxy.name"
  default     = false
}

variable "aws_db_proxy_cloudwatch_retention_days" {
  type        = string
  description = "Number of days to retain logs"
  default     = "14"
}

variable "aws_db_proxy_additional_tags" {
  type        = string
  description = "A list of strings that will be added to created resources"
  default     = "{}"
}

# Redis
variable "aws_redis_enable" {
  type        = bool
  description = "Enables the creation of a Redis instance"
  default     = false
}

variable "aws_redis_user" {
  type        = string
  description = "Redis username. Defaults to redisuser"
  default     = "redisuser"
}

variable "aws_redis_user_access_string" {
  type        = string
  description = "String expression for user access. Defaults to on ~* +@all"
  default     = "on ~* +@all"
}

variable "aws_redis_user_group_name" {
  type        = string
  description = "User group name. Defaults to aws_resource_identifier-redis"
  default     = ""
}

variable "aws_redis_security_group_name" {
  type        = string
  description = "Redis security group name. Defaults to SG for aws_resource_identifier - Redis"
  default     = ""
}

variable "aws_redis_ingress_allow_all" {
  type        = bool
  description = "Allow access from 0.0.0.0/0 in the same VPC"
  default     = true
}

variable "aws_redis_allowed_security_groups" {
  type        = string
  description = "Comma separated list of security groups to be added to the Redis SG."
  default     = ""
}

variable "aws_redis_subnets" {
  type        = string
  description = "Define a list of specific subnets where Redis will live. Defaults to all of the VPC ones. If not defined, default VPC."
  default     = ""
}

variable "aws_redis_port" {
  type        = string
  description = "Redis port. Defaults to 6379"
  default     = "6379"
}

variable "aws_redis_at_rest_encryption" {
  type        = bool
  description = "Encryption at rest. Defaults to true."
  default     = true
}

variable "aws_redis_in_transit_encryption" {
  type        = bool
  description = "In-transit encryption. Defaults to true."
  default     = true
}

variable "aws_redis_replication_group_id" {
  type        = string
  description = "Name of the Redis replication group. Defaults to aws_resource_identifier-redis"
  default     = ""
}

variable "aws_redis_node_type" {
  type        = string
  description = "Node type of the Redis instance. Defaults to cache.t2.small"
  default     = "cache.t2.small"
}

variable "aws_redis_num_cache_clusters" {
  type        = string
  description = "Amount of Redis nodes. Defaults to 1"
  default     = "1"
}

variable "aws_redis_parameter_group_name" {
  type        = string
  description = "Redis parameters groups name. If cluster wanted, set it to something that includes .cluster.on. Defaults to default.redis7"
  default     = "default.redis7"
}

variable "aws_redis_num_node_groups" {
  type        = string
  description = "Number of node groups. Defaults to 0."
  default     = null
}

variable "aws_redis_replicas_per_node_group" {
  type        = string
  description = "Number of replicas per node group. Defaults to 0"
  default     = null
}

variable "aws_redis_multi_az_enabled" {
  type        = bool
  description = "Enables multi-availability-zone redis. Defaults to false"
  default     = false
}

variable "aws_redis_automatic_failover" {
  type        = bool
  description = "Allows overriding the automatic configuration of this value, only needed when playing with resources in a non-conventional way."
  default     = null
}

variable "aws_redis_apply_immediately" {
  type        = bool
  description = "Specifies whether any modifications are applied immediately, or during the next maintenance window. Default is false."
  default     = false
}

variable "aws_redis_auto_minor_upgrade" {
  type        = bool
  description = "Specifies whether minor version engine upgrades will be applied automatically to the underlying Cache Cluster instances during the maintenance window. Defaults to true."
  default     = true
}

variable "aws_redis_maintenance_window" {
  type        = string
  description = "Specifies the weekly time range for when maintenance on the cache cluster is performed. Example:sun:05:00-sun:06:00. Defaults to null."
  default     = null
}

variable "aws_redis_snapshot_window" {
  type        = string
  description = "Daily time range (in UTC) when to start taking a daily snapshot. Minimum is a 60 minute period. Example: 05:00-09:00. Defaults to null."
  default     = null
}

variable "aws_redis_final_snapshot" {
  type        = string
  description = "Change name to define a final snapshot."
  default     = ""
}

variable "aws_redis_snapshot_restore_name" {
  type        = string
  description = "Set name to restore a snapshot to the cluster. The default behaviour is to restore it each time this action runs."
  default     = ""
}

variable "aws_redis_cloudwatch_enabled" {
  type        = bool
  description = "Enable or disables Cloudwatch logging."
  default     = true
}

variable "aws_redis_cloudwatch_lg_name" {
  type        = string
  description = "Cloudwatch log group name. Defaults to redis/aws_resource_identifier. Will append log_type to it."
  default     = ""
}

variable "aws_redis_cloudwatch_log_format" {
  type        = string
  description = "Define log format between json (default) and text."
  default     = "json"
}

variable "aws_redis_cloudwatch_log_type" {
  type        = string
  description = "Log type. Older Redis engines need slow-log. Newer support engine-log (default)"
  default     = "engine-log"
}

variable "aws_redis_cloudwatch_retention_days" {
  type        = string
  description = "Number of days to retain logs. 0 to never expire."
  default     = "14"
}

variable "aws_redis_single_line_url_secret" {
  type        = bool
  description = "Creates an AWS secret containing the connection string containing protocol://user@pass:endpoint:port"
  default     = false
}

variable "aws_redis_additional_tags" {
  type        = string
  description = "Additional tags to be added to every Redis related resource"
  default     = "{}"
}

# Docker

variable "docker_efs_mount_target" {
  type        = string
  description = "Directory path in efs to mount to"
  default     = "/data"
}

variable "docker_remove_orphans" {
  type        = bool
  description = "define if ansible should clean orphans"
  default     = false
}

variable "docker_cloudwatch_enable" {
  type        = bool
  description = "Toggle cloudwatch for Docker."
  default     = false
}

variable "docker_cloudwatch_lg_name" {
  type        = string
  description = "Log group name. Will default to aws_identifier if none."
  default     = ""
}

variable "docker_cloudwatch_skip_destroy" {
  type        = bool
  description = "Toggle deletion or not when destroying the stack."
  default     = false
}

variable "docker_cloudwatch_retention_days" {
  type        = string
  description = "Number of days to retain logs. 0 to never expire."
  default     = "14"
}

# ECS
variable "aws_ecs_enable" {
  type        = bool
  description = "Toggle ECS Creation"
  default     = false
}

variable "aws_ecs_service_name" {
  type        = string
  description = "Elastic Container Service name"
  default     = ""
}

variable "aws_ecs_cluster_name" {
  type        = string
  description = "Elastic Container Service cluster name"
  default     = ""
}

variable "aws_ecs_service_launch_type" {
  type        = string
  description = "Configuration type. Could be EC2, FARGATE or EXTERNAL"
  default     = "FARGATE"
}

variable "aws_ecs_task_type" {
  type        = string
  description = "Configuration type. Could be EC2, FARGATE or empty. Will default to aws_ecs_service_launch_type if none defined. (Blank if EXTERNAL)"
  default     = ""
}

variable "aws_ecs_task_name" {
  type        = string
  description = "Elastic Container Service task name"
  default     = ""
}

variable "aws_ecs_task_ignore_definition" {
  type        = bool
  description = "Toggle ignoring changes to the task definition"
  default     = false
}

variable "aws_ecs_task_execution_role" {
  type        = string
  description = "Elastic Container Service task execution role name."
  default     = ""
}

variable "aws_ecs_task_json_definition_file" {
  type        = string
  description = "Filename for json file containing ECS conteiner definitions"
  default     = ""
}

variable "aws_ecs_task_network_mode" {
  type        = string
  description = "Network type to use in task definition"
  default     = ""
}

variable "aws_ecs_task_cpu" {
  type        = string
  description = "Task CPU Amount"
  default     = ""
}

variable "aws_ecs_task_mem" {
  type        = string
  description = "Task Mem Amount"
  default     = ""
}

variable "aws_ecs_container_cpu" {
  type        = string
  description = "Container CPU Amount"
  default     = ""
}

variable "aws_ecs_container_mem" {
  type        = string
  description = "Container Mem Amount"
  default     = ""
}

variable "aws_ecs_node_count" {
  type        = string
  description = "Node count for ECS Cluster"
  default     = ""
}

variable "aws_ecs_app_image" {
  type        = string
  description = "Name of the image to be used"
  default     = ""
}

variable "aws_ecs_security_group_name" {
  type        = string
  description = "ECS Secruity group name"
  default     = ""
}

variable "aws_ecs_assign_public_ip" {
  type        = bool
  description = "Assign public IP to node"
  default     = false
}

variable "aws_ecs_container_port" {
  type        = string
  description = "Comma separated list of container ports"
  default     = ""
}

variable "aws_ecs_lb_port" {
  type        = string
  description = "Comma serparated list of ports exposed by the load balancer"
  default     = ""
}

variable "aws_ecs_lb_redirect_enable" {
  type        = bool
  description = "Toggle redirect from HTTP and/or HTTPS to the main container port"
  default     = false
}

variable "aws_ecs_lb_container_path" {
  type        = string
  description = "Path for subsequent images. eg. api"
  default     = ""
}

variable "aws_ecs_lb_ssl_policy" {
  type        = string
  description = "SSL Policy to use in the ALB HTTPS protocol"
  default     = "ELBSecurityPolicy-TLS13-1-2-2021-06"
}

variable "aws_ecs_lb_www_to_apex_redirect" {
  type        = bool
  description = "Toggle redirect from www to apex domain. Need aws_r53_domain_name variable defined."
  default     = false
}

variable "aws_ecs_autoscaling_enable" {
  type        = bool
  description = "Toggle ecs autoscaling policy"
  default     = "false"
}

variable "aws_ecs_autoscaling_max_nodes" {
  type        = string
  description = "Max ammount of nodes to scale up to."
  default     = ""
}

variable "aws_ecs_autoscaling_min_nodes" {
  type        = string
  description = "Min ammount of nodes to scale down to."
  default     = ""
}

variable "aws_ecs_autoscaling_max_mem" {
  type        = string
  description = "Max memory percentage usage"
  default     = ""
}

variable "aws_ecs_autoscaling_max_cpu" {
  type        = string
  description = "Max CPU percentage usage"
  default     = ""
}

variable "aws_ecs_cloudwatch_enable" {
  type        = bool
  description = "Toggle cloudwatch for ECS."
  default     = false
}

variable "aws_ecs_cloudwatch_lg_name" {
  type        = string
  description = "Log group name. Will default to aws_identifier if none."
  default     = null
}

variable "aws_ecs_cloudwatch_skip_destroy" {
  type        = string
  description = "Toggle deletion or not when destroying the stack."
  default     = null
}

variable "aws_ecs_cloudwatch_retention_days" {
  type        = string
  description = "Number of days to retain logs. 0 to never expire."
  default     = "14"
}

variable "aws_ecs_additional_tags" {
  type        = string
  description = "A list of strings that will be added to created resources"
  default     = "{}"
}

# ECR
variable "aws_ecr_repo_create" { 
  description = "Determines whether a repository will be created"
  type        = bool
  default     = false
}

variable "aws_ecr_repo_type" { 
  description = "The type of repository to create. Either `public` or `private`"
  type        = string
  default     = "private"
}

variable "aws_ecr_repo_name" {
  description = "The name of the repository. Will use the default resource-identifier"
  type        = string
  default     = ""
}

variable "aws_ecr_repo_mutable" {
  description = "The tag mutability setting for the repository. Set this to true if `MUTABLE`. Defaults to false, so `IMMUTABLE`"
  type        = bool
  default     = false
}

variable "aws_ecr_repo_encryption_type" {
  description = "The encryption type for the repository. Must be one of: `KMS` or `AES256`. Defaults to `AES256`"
  type        = string
  default     = "AES256"
}

variable "aws_ecr_repo_encryption_key_arn" {
  description = "The ARN of the KMS key to use when encryption_type is `KMS`. If not specified, uses the default AWS managed key for ECR"
  type        = string
  default     = null
}

variable "aws_ecr_repo_force_destroy" {
  description = "If `true`, will delete the repository even if it contains images. Defaults to `false`"
  type        = bool
  default     = null
}

variable "aws_ecr_repo_image_scan" {
  description = "Indicates whether images are scanned after being pushed to the repository (`true`) or not scanned (`false`)"
  type        = bool
  default     = true
}

variable "aws_ecr_registry_scan_rule" {
  description = "One or multiple blocks specifying scanning rules to determine which repository filters are used and at what frequency scanning will occur"
  type        = any
  default     = []
}

variable "aws_ecr_registry_pull_through_cache_rules" {
  description = "List of pull through cache rules to create"
  type        = map(map(string))
  default     = {}
}

variable "aws_ecr_registry_scan_config" {
  description = "the scanning type to set for the registry. Can be either `ENHANCED` or `BASIC`. Defaults to null."
  type        = string
  default     = ""
}

variable "aws_ecr_registry_replication_rules_input" {
  description = "The replication rules for a replication configuration. A maximum of 10 are allowed"
  type        = any
  default     = []
}

# ECR Policies

variable "aws_ecr_repo_policy_attach" {
  description = "Determines whether a repository policy will be attached to the repository"
  type        = bool
  default     = true
}

variable "aws_ecr_repo_policy_create" {
  description = "Determines whether a repository policy will be created. Defaults to true."
  type        = bool
  default     = true
}

variable "aws_ecr_repo_policy_input" {
  description = "The JSON policy to apply to the repository. If defined overrides the default policy"
  type        = string
  default     = ""
}

variable "aws_ecr_repo_read_arn" {
  description = "The ARNs of the IAM users/roles that have read access to the repository"
  type        = string
  default     = ""
}

variable "aws_ecr_repo_write_arn" {
  description = "The ARNs of the IAM users/roles that have read/write access to the repository"
  type        = string
  default     = ""
}

variable "aws_ecr_repo_read_arn_lambda" {
  description = "The ARNs of the Lambda service roles that have read access to the repository"
  type        = string
  default     = ""
}

variable "aws_ecr_lifecycle_policy_input" {
  description = "The policy document. This is a JSON formatted string. See more details about [Policy Parameters](http://docs.aws.amazon.com/AmazonECR/latest/userguide/LifecyclePolicies.html#lifecycle_policy_parameters) in the official AWS docs"
  type        = string
  default     = ""
}

variable "aws_ecr_repo_read_external_aws_account" {
  description = "The ARNs of the external AWS accounts that have read access to the repository"
  type        = string
  default     = ""
}

variable "aws_ecr_repo_write_external_aws_account" {
  description = "The ARNs of the external AWS accounts that have write access to the repository"
  type        = string
  default     = ""
}

variable "aws_ecr_public_repo_catalog" {
  description = "Catalog data configuration for the repository"
  type        = any
  default     = {}
}

variable "aws_ecr_registry_policy_input" { 
  description = "The policy document. This is a JSON formatted string"
  type        = string
  default     = ""
}

variable "aws_ecr_additional_tags" {
  type        = string
  description = "A list of strings that will be added to created resources"
  default     = "{}"
}

# EKS
variable "aws_eks_create" {
  type        = bool
  description = "deploy a eks cluster"
  default     = false
}

variable "aws_eks_security_group_name_cluster" {
  description = "aws aws_eks_security_group_name_cluster name"
  type        = string
  default     = ""
}

variable "aws_eks_security_group_name_node" {
  description = "aws aws_eks_security_group_name_node name"
  type        = string
  default     = ""
}

variable "aws_eks_environment" {
  description = "eks environment name"
  type        = string
  default     = "env"
}

variable "aws_eks_management_cidr" {
  type        = string
  description = "your local workstation public IP"
  default     = ""
}

variable "aws_eks_allowed_ports" {
  type        = string
  description = "Allow incoming traffic from this port. Accepts comma separated values, matching 1 to 1 with aws_eks_allowed_ports_cidr."
  default     = ""
}
variable "aws_eks_allowed_ports_cidr" {
  type        = string
  description = "Allow incoming traffic from this CIDR block. Accepts comma separated values, matching 1 to 1 with aws_eks_allowed_ports. If none defined, will allow all incoming traffic"
  default     = ""
}

variable "aws_eks_cluster_name" {
  description = "kubernetes cluster name"
  type        = string
  default     = ""
}

variable "aws_eks_cluster_admin_role_arn" {
  description = "Role ARN to grant cluster-admin permissions"
  type        = string
  default     = ""
}

variable "aws_eks_cluster_log_types" {
  description = "Comma separated list of log-types"
  type        = string
  default     = "api,audit,authenticator"
}

variable "aws_eks_cluster_log_retention_days" {
  description = "enter the kubernetes version"
  type        = string
  default     = "7"
}

variable "aws_eks_cluster_log_skip_destroy" {
  type        = string
  description = "Toggle deletion or not when destroying the stack."
  default     = false
}

variable "aws_eks_cluster_version" {
  description = "enter the kubernetes version"
  type        = number
  default     = "1.28"
}

variable "aws_eks_instance_type" {
  description = "enter the aws instance type"
  type        = string
  default     = "t3a.medium"
}

variable "aws_eks_instance_ami_id" {
  description = "AWS AMI ID"
  type        = string
  default     = ""
}

variable "aws_eks_instance_user_data_file" {
  description = "enter the aws instance user data file"
  type        = string
  default     = ""
}

variable "aws_eks_ec2_key_pair" {
  description = "Enter the existing ec2 key pair for worker nodes"
  type        = string
  default     = ""
}

variable "aws_eks_store_keypair_sm" {
  description = "y/n create sm entry for ec2 keypair"
  type        = bool
  default     = false
}

variable "aws_eks_desired_capacity" {
  description = "Enter the desired capacity for the worker nodes"
  type        = number
  default     = "2"
}

variable "aws_eks_max_size" {
  description = "Enter the max_size for the worker nodes"
  type        = number
  default     = "4"
}

variable "aws_eks_min_size" {
  description = "Enter the min_size for the worker nodes"
  type        = number
  default     = "2"
}

variable "aws_eks_additional_tags" {
  type        = string
  description = "A list of strings that will be added to created resources"
  default     = "{}"
}

#### END OF ACTION VARIABLES INPUTS
#### The following are not being exposed directly to the end user

variable "app_repo_name" {
  type        = string
  description = "GitHub Repo Name"
  default     = ""
}
variable "app_org_name" {
  type        = string
  description = "GitHub Org Name"
  default     = ""
}
variable "app_branch_name" {
  type        = string
  description = "GitHub Branch Name"
  default     = ""
}

variable "app_install_root" {
  type        = string
  description = "Path on the instance where the app will be cloned (do not include app_repo_name)."
  default     = "/home/ubuntu"
}

variable "os_system_user" {
  type        = string
  description = "User for the OS"
  default     = "ubuntu"
}

variable "ops_repo_environment" {
  type        = string
  description = "Ops Repo Environment (i.e. directory name)"
  default     = ""
}

# AWS Common

variable "availability_zone" {
  type        = string
  description = "The AZ zone to deploy resources to"
  default     = null
}

# Need an empty line to append incoming variables. 
