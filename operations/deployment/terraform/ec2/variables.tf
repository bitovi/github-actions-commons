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
  type        = map(string)
  description = "A list of strings that will be added to created resources"
  default     = {}
}

# ENV Files

variable "env_aws_secret" {
  type        = string
  description = "Secret name to pull env variables from AWS Secret Manager"
  default     = null
}

# EC2 Instance

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

# AWS Route53 Domains abd Certificates

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


# AWS ELB


variable "aws_elb_app_port" {
  type        = string
  default     = "3000"
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
  default     = ""
  description = "Load balancer health check string. Defaults to HTTP:aws_elb_app_port"
}

# AWS EFS

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

variable "aws_efs_create_replica" {
  type        = bool
  description = "Toggle to indiciate whether a read-only replica should be created for the EFS primary file system"
  default     = false
}

variable "aws_efs_enable_backup_policy" {
  type        = bool
  default     = false
  description = "Toggle to indiciate whether the EFS should have a backup policy, default is `false`"
}

variable "aws_efs_zone_mapping" {
  type = map(object({
    subnet_id       = string
    security_groups = list(string)
  }))
  description = "Zone Mapping in the form of {\"<availabillity zone>\":{\"subnet_id\":\"subnet-abc123\", \"security_groups\":[\"sg-abc123\"]} }"
  nullable    = true
  default     = null
}

variable "aws_efs_transition_to_inactive" {
  type        = string
  default     = "AFTER_30_DAYS"
  description = "https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/efs_file_system#transition_to_ia"
}

variable "aws_efs_replication_destination" {
  type        = string
  default     = null
  description = "AWS Region to target for replication"
}

variable "aws_efs_mount_id" {
  type        = string
  description = "ID of existing EFS"
  default     = null
}

variable "aws_efs_mount_security_group_id" {
  type        = string
  description = "ID of the primary security group used by the existing EFS"
  default     = null
}

variable "aws_efs_mount_target" {
  type        = string
  description = "Directory path in efs to mount to"
  default     = null
}

variable "aws_efs_ec2_mount_point" {
  type        = string
  description = "Directory path in application env to mount directory"
  default = "data"
}

# AWS RDS

variable "aws_postgres_enable" {
  type        = bool
  description = "deploy a postgres database"
  default     = false
}
variable "aws_postgres_engine" {
  type        = string
  description = "The engine to use for postgres.  Defaults to `aurora-postgresql`.  For more details, see: https://aws.amazon.com/rds/, https://registry.terraform.io/modules/terraform-aws-modules/rds-aurora/aws/latest?tab=inputs"
  default     = "aurora-postgresql"
}
variable "aws_postgres_engine_version" {
  type        = string
  description = "The version of the engine to use for postgres.  Defaults to `11.13`."
  default     = "11.13"
}
variable "aws_postgres_instance_class" {
  type        = string
  description = "The size of the db instances.  For more details, see: https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Concepts.DBInstanceClass.html, https://registry.terraform.io/modules/terraform-aws-modules/rds-aurora/aws/latest?tab=inputs"
  default     = "db.t3.medium"
}
variable "aws_postgres_security_group_name" {
  type        = string
  default     = ""
  description = "Name of the security group to use for postgres"
}
variable "aws_postgres_subnets" {
  type        = list(string)
  description = "The list of subnet ids to use for postgres. For more details, see: https://registry.terraform.io/modules/terraform-aws-modules/rds-aurora/aws/latest?tab=inputs"
  default     = []
}
variable "aws_postgres_database_name" {
  type        = string
  description = "The name of the database. will be created if it does not exist."
  default     = "root"
}
variable "aws_postgres_database_port" {
  type        = string
  default     = "5432"
  description = "database port"
}

variable "aws_postgres_database_protection" {
  type        = bool
  default     = false
  description = "Protects the database from deletion."
}

variable "aws_postgres_database_final_snapshot" {
  type        = string
  default     = ""
  description = "Generates a snapshot of the database before deletion."
}

# Docker

variable "docker_efs_mount_target" {
  type        = string
  description = "Directory path in efs to mount to"
  default     = "/data"
}


#### END OF ACTION VARIABLES INPUTS

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

# EC2 


# POSTGRES


# ELB
variable "lb_access_bucket_name" {
  type        = string
  description = "s3 bucket for the lb access logs"
}

# Need an empty line to append incoming variables. 

