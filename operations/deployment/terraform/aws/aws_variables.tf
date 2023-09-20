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
}

variable "aws_resource_identifier_supershort" {
  type        = string
  description = "Identifier to use for AWS resources (defaults to GITHUB_ORG-GITHUB_REPO-GITHUB_BRANCH) shortened to 30 chars"
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
  default     = "t2.small"
  description = "Instance type for the EC2 instance"
}

variable "aws_ec2_instance_root_vol_size" {
  type        = string
  default     = "8"
  description = "Instance type for the EC2 instance"
}

variable "aws_ec2_instance_root_vol_preserve" {
  type        = bool
  default     = false
  description = "Set this to true to avoid deletion of root volume on termination."
}

variable "aws_ec2_security_group_name" {
  type        = string
  default     = ""
  description = "Name of the security group to use"
}

variable "aws_ec2_create_keypair_sm" {
  type        = bool
  description = "y/n create sm entry for ec2 keypair"
  default     = false
}

variable "aws_ec2_instance_public_ip" {
  type        = bool
  default     = false
  description = "Attach public IP to the EC2 instance"
}

variable "aws_ec2_port_list" {
  type = string
  default = ""
}

variable "aws_ec2_user_data_replace_on_change"  {
  type        = bool
  default     = true
  description = "Forces destruction of EC2 instance"
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
  description = "CIDR of the VPC"
  type        = string
  default     = "10.10.0.0/16"
}

variable "aws_vpc_public_subnets" {
  type        = string
  default     = "10.10.110.0/24"
  description = "A list of public subnets"
}

variable "aws_vpc_private_subnets" {
  type        = string
  default     = ""
  description = "A list of private subnets"
}

variable "aws_vpc_availability_zones" {
  type        = string
  default     = ""
  description = "A list of availability zones."
}

variable "aws_vpc_additional_tags" {
  type        = string
  description = "A list of strings that will be added to created resources"
  default     = "{}"
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
  default     = ""
  description = "Name of the security group to use"
}

variable "aws_elb_app_port" {
  type        = string
  default     = ""
  description = "app port"
}

variable "aws_elb_app_protocol" {
  type        = string
  default     = "tcp"
  description = "Protocol to enable. Could be HTTP, HTTPS, TCP or SSL."
}

variable "aws_elb_listen_port" {
  type        = string
  default     = ""
  description = "Load balancer listening port. Defaults to 80 if NO FQDN provided, 443 if FQDN provided"
}

variable "aws_elb_listen_protocol" {
  type        = string
  default     = ""
  description = "Protocol to enable. Could be HTTP, HTTPS, TCP or SSL. Defaults to TCP if NO FQDN provided, SSL if FQDN provided"
}

variable "aws_elb_healthcheck" {
  type        = string
  default     = "TCP:22"
  description = "Load balancer health check string. Defaults to TCP:22"
}

variable "aws_elb_additional_tags" {
  type        = string
  description = "A list of strings that will be added to created resources"
  default     = "{}"
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

variable "aws_efs_create_ha" {
  type        = bool
  description = "Toggle to indicate whether the EFS resource should be highly available (target mounts in all available zones within region)."
  default     = false
}

variable "aws_efs_fs_id" {
  type        = string
  description = "ID of existing EFS"
  default     = null
}

variable "aws_efs_vpc_id" {
  type        = string
  description = "ID of the VPC for the EFS mount target. If aws_efs_create_ha is set to true, will create one mount target per subnet available in the VPC."
  default     = null
}

variable "aws_efs_subnet_ids" {
  type        = string
  description = "ID of the VPC for the EFS mount target. If aws_efs_create_ha is set to true, will create one mount target per subnet available in the VPC."
  default     = null
}

variable "aws_efs_security_group_name" {
  type        = string
  default     = ""
  description = "Name of the security group to use"
}

variable "aws_efs_create_replica" {
  type        = bool
  description = "Toggle to indiciate whether a read-only replica should be created for the EFS primary file system"
  default     = false
}

variable "aws_efs_replication_destination" {
  type        = string
  default     = ""
  description = "AWS Region to target for replication"
}

variable "aws_efs_enable_backup_policy" {
  type        = bool
  default     = false
  description = "Toggle to indiciate whether the EFS should have a backup policy, default is `false`"
}

variable "aws_efs_transition_to_inactive" {
  type        = string
  default     = "AFTER_30_DAYS"
  description = "https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/efs_file_system#transition_to_ia"
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
  default     = null
}

variable "aws_rds_db_name" {
  type        = string
  description = "The name of the database to create when the DB instance is created. If this parameter is not specified, no database is created in the DB instance."
  default     = null
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

variable "aws_rds_db_security_group_name" {
  type        = string
  description = "The name of the database security group. Defaults to SG for aws_resource_identifier - RDS"
  default     = null
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

variable "aws_rds_db_instance_class" {
  type        = string
  description = "Server size"
  default     = "db.t3.micro"
}

variable "aws_rds_db_user" {
  type        = string
  description = "user"
  default     = "dbuser"
}

variable "aws_rds_cloudwatch_logs_exports" {
  type        = string
  description = "logs exports"
  default     = null
}

variable "aws_rds_additional_tags" {
  type        = string
  description = "A list of strings that will be added to created resources"
  default     = "{}"
}

# AWS Aurora

variable "aws_aurora_enable" {
  type        = bool
  description = "deploy a postgres database"
  default     = false
}
variable "aws_aurora_engine" {
  type        = string
  description = "The engine to use for postgres.  Defaults to `aurora-postgresql`.  For more details, see: https://aws.amazon.com/rds/, https://registry.terraform.io/modules/terraform-aws-modules/rds-aurora/aws/latest?tab=inputs"
  default     = "aurora-postgresql"
}
variable "aws_aurora_engine_version" {
  type        = string
  description = "The version of the engine to use for postgres.  Defaults to `11.17`."
  default     = "11.17"
}
variable "aws_aurora_database_group_family" {
  type        = string
  default     = "aurora-postgresql11"
  description = "postgres group family"
}
variable "aws_aurora_instance_class" {
  type        = string
  description = "The size of the db instances.  For more details, see: https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Concepts.DBInstanceClass.html, https://registry.terraform.io/modules/terraform-aws-modules/rds-aurora/aws/latest?tab=inputs"
  default     = "db.t3.medium"
}
variable "aws_aurora_security_group_name" {
  type        = string
  default     = ""
  description = "Name of the security group to use for postgres"
}
variable "aws_aurora_subnets" {
  type        = string
  description = "The list of subnet ids to use for postgres. For more details, see: https://registry.terraform.io/modules/terraform-aws-modules/rds-aurora/aws/latest?tab=inputs"
  default     = ""
}
variable "aws_aurora_cluster_name" {
  type        = string
  description = "The name of the cluster. will be created if it does not exist."
  default     = ""
}
variable "aws_aurora_database_name" {
  type        = string
  description = "The name of the database. will be created if it does not exist."
  default     = "root"
}
variable "aws_aurora_database_port" {
  type        = string
  default     = "5432"
  description = "database port"
}
variable "aws_aurora_restore_snapshot" {
  type        = string
  default     = ""
  description = "Restore an initial snapshot of the DB."
}
variable "aws_aurora_snapshot_name" {
  type        = string
  default     = ""
  description = "Takes a snapshot of the DB."
}
variable "aws_aurora_snapshot_overwrite" {
  type        = bool
  default     = false
  description = "Overwrites snapshot."
}
variable "aws_aurora_database_protection" {
  type        = bool
  default     = false
  description = "Protects the database from deletion."
}
variable "aws_aurora_database_final_snapshot" {
  type        = string
  default     = ""
  description = "Generates a snapshot of the database before deletion."
}

variable "aws_aurora_additional_tags" {
  type        = string
  description = "A list of strings that will be added to created resources"
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

variable "aws_eks_region" {
  description = "aws region name"
  type        = string
  default     = "us-east-1"
}

variable "aws_eks_security_group_name_master" {
  description = "aws aws_eks_security_group_name_master name"
  type        = string
  default     = ""
}

variable "aws_eks_security_group_name_worker" {
  description = "aws aws_eks_security_group_name_worker name"
  type        = string
  default     = ""
}

variable "aws_eks_vpc_name" {
  description = "aws aws_eks_security_group_name_worker name"
  type        = string
  default     = ""
}

variable "aws_eks_environment" {
  description = "eks environment name"
  type        = string
  default     = "env"
}

variable "aws_eks_stackname" {
  description = "enter the eks stack name"
  type        = string
  default     = "eks-stack"
}

variable "aws_eks_cidr_block" {
  type        = string
  description = "Base CIDR block which is divided into subnet CIDR blocks (e.g. `10.0.0.0/16`)"
  default     = "10.0.0.0/16"
}

variable "aws_eks_workstation_cidr" {
  type        = string
  description = "your local workstation public IP"
  default     = ""
}

variable "aws_eks_availability_zones" {
  type        = string
  description = "List of Availability Zones (e.g. `['us-east-1a', 'us-east-1b', 'us-east-1c']`)"
  default     = "us-east-1a,us-east-1b"
}

variable "aws_eks_private_subnets" {
  type        = string
  description = "List of private subnets (e.g. `['10.0.1.0/24', '10.0.2.0/24']`)"
  default     = "10.0.1.0/24,10.0.2.0/24"
}

variable "aws_eks_public_subnets" {
  type        = string
  description = "List of public subnets (e.g. `['10.0.101.0/24', '10.0.102.0/24']`)"
  default     = "10.0.101.0/24,10.0.102.0/24"
}

variable "aws_eks_cluster_name" {
  description = "kubernetes cluster name"
  type        = string
  default     = ""
}

variable "aws_eks_cluster_log_types" {
  description = "enter the kubernetes version"
  type        = string
  default     = ""
}

variable "aws_eks_cluster_version" {
  description = "enter the kubernetes version"
  type        = number
  default     = "1.27"
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
}
variable "app_org_name" {
  type        = string
  description = "GitHub Org Name"
}
variable "app_branch_name" {
  type        = string
  description = "GitHub Branch Name"
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
}

# AWS Common

variable "availability_zone" {
  type        = string
  default     = null
  description = "The AZ zone to deploy resources to"
}

# ELB
variable "lb_access_bucket_name" {
  type        = string
  description = "s3 bucket for the lb access logs"
}

# Need an empty line to append incoming variables. 
