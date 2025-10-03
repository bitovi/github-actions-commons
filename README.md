# Bitovi Github Actions Commons
![alt](https://bitovi-gha-pixel-tracker-deployment-main.bitovi-sandbox.com/pixel/xPr-DmChd-IUA5Pa0Aam7)
This is a work in progress to embed a root tool to deploy wrapper actions in order to trim the excess of inputs yet be flexible. 

## Getting Started Intro Video
No video for now. Sorry. :disappointed:

## Need help or have questions?
This project is supported by [Bitovi, a DevOps Consultancy](https://www.bitovi.com/devops-consulting) and a proud supporter of Open Source software.

You can **get help or ask questions** on [Discord channel](https://discord.gg/zAHn4JBVcX)! Come hangout with us!

Or, you can hire us for training, consulting, or development. [Set up a free consultation](https://www.bitovi.com/devops-consulting).

## Requirements

Not defined for now. 

## Environment variables

Not defined for now.

## Example usage

Create `.github/workflow/deploy.yaml` with the following to build on push.

### Basic example
```yaml
name: Basic deploy
on:
  push:
    branches: [ main ]

jobs:
  EC2-Deploy:
    runs-on: ubuntu-latest
    steps:
      - id: deploy
        uses: bitovi/github-actions-deploy-commons@main # <--- Check version to use, main for now.
        with:
          aws_access_key_id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws_secret_access_key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws_default_region: us-east-1
          env_ghs: ${{ secrets.DOT_ENV }}
          additional_tags: '{\"key\":\"value\",\"key2\":\"value2\"}'
```

## Customizing

### Inputs
1. [GitHub Deployment repo inputs](#github-deployment-repo-inputs)
1. [GitHub Action repo inputs](#github-action-repo-inputs)
1. [Action default inputs](#action-default-inputs)
1. [AWS Specific](#aws-specific)
1. [Secrets and Environment Variables](#secrets-and-environment-variables-inputs)
1. [EC2](#ec2-inputs)
1. [VPC](#vpc-inputs)
1. [AWS Route53 Domains and Certificates](#aws-route53-domains-and-certificate-inputs)
1. [Load Balancer](#load-balancer-inputs)
1. [WAF](#waf)
1. [EFS](#efs-inputs)
1. [RDS](#rds-inputs)
1. [Amazon Aurora Inputs](#aurora-inputs)
1. [Docker](#docker-inputs)
1. [Redis](#redis-inputs)
1. [ECS](#ecs-inputs)
1. [ECR](#ecr-inputs)
1. [EKS](#eks-inputs)

### Outputs
1. [Action Outputs](#action-outputs)

The following inputs can be used as `step.with` keys
<br/>
<br/>

#### **GitHub Deployment repo inputs**
| Name             | Type    | Description                        |
|------------------|---------|------------------------------------|
| `gh_deployment_input_terraform` | String | Folder to store Terraform files to be included during Terraform execution.|
| `gh_deployment_input_ansible` | String | Folder where a whole Ansible structure is expected. If missing bitops.config.yaml a default will be generated.|
| `gh_deployment_input_ansible_playbook` | String | Main playbook to be looked for. Defaults to `playbook.yml`.|
| `gh_deployment_input_ansible_extra_vars_file` | String | Relative path to Ansible extra-vars file. |
| `gh_deployment_action_input_ansible_extra_vars_file` | String | Relative path to Ansible extra-vars file from deployment to be set up into the action Ansible code. |
| `gh_deployment_input_helm_charts` | String | Relative path to the folder from project containing Helm charts to be installed. Could be uncompressed or compressed (.tgz) files. |
<hr/>
<br/>

#### **GitHub Action repo inputs**
| Name             | Type    | Description                        |
|------------------|---------|------------------------------------|
| `gh_action_repo` | String | URL of calling repo. |
| `gh_action_input_terraform` | String | Folder to store Terraform files to be included during Terraform execution. |
| `gh_action_input_ansible` | String | Folder where a whole Ansible structure is expected. If missing bitops.config.yaml a default will be generated. |
| `gh_action_input_ansible_playbook` | String | Main playbook to be looked for. Defaults to `playbook.yml`.|
| `gh_action_input_helm_charts` | String | Relative path to the folder from action containing Helm charts to be installed. Could be uncompressed or compressed (.tgz) files. |
<hr/>
<br/>

#### **GitHub Commons main inputs**
| Name             | Type    | Description                        |
|------------------|---------|------------------------------------|
| `checkout` | Boolean | Set to `false` if the code is already checked out. (Default is `true`). |
| `bitops_code_only` | Boolean | If `true`, will run only the generation phase of BitOps, where the Terraform and Ansible code is built. |
| `bitops_code_store` | Boolean | Store BitOps generated code as a GitHub artifact. |
| `bitops_extra_env_vars` | String | Variables to be passed to BitOps as Docker extra vars. Format should be `-e KEY1=VALUE1 -e KEY2=VALUE2`. |
| `bitops_extra_env_vars_file` | String | `.env` file to pass to BitOps Docker run. Usefull for long variables. |
| `tf_stack_destroy` | Boolean  | Set to `true` to destroy the stack - Will delete the `elb logs bucket` after the destroy action runs. |
| `tf_state_file_name` | String | Change this to be anything you want to. Carefull to be consistent here. A missing file could trigger recreation, or stepping over destruction of non-defined objects. Defaults to `tf-state-aws`, `tf-state-ecr` or `tf-state-eks.` |
| `tf_state_file_name_append` | String | Appends a string to the tf-state-file. Setting this to `unique` will generate `tf-state-aws-unique`. (Can co-exist with `tf_state_file_name`) |
| `tf_state_bucket` | String | AWS S3 bucket name to use for Terraform state. See [note](#s3-buckets-naming) | 
| `tf_state_bucket_destroy` | Boolean | Force purge and deletion of S3 bucket defined. Any file contained there will be destroyed. `tf_stack_destroy` must also be `true`. Default is `false`. |
| `tf_state_bucket_provider` | String | Bucket provider for Terraform State storage. [Disabled ATM, AWS as a default.] | 
| `tf_targets` | List | A list of targets to create before the full stack creation. | 
| `ansible_skip` | Boolean | Skip Ansible execution after Terraform excecution. Default is `false`.|
| `ansible_ssh_to_private_ip` | Boolean | Make Ansible connect to the private IP of the instance. Only usefull if using a hosted runner in the same network. Default is `false`. | 
| `ansible_start_docker_timeout` | String | Ammount of time in seconds it takes Ansible to mark as failed the startup of docker. Defaults to `300`.|
<hr/>
<br/>

#### **AWS Specific**
| Name             | Type    | Description                        |
|------------------|---------|------------------------------------|
| `aws_access_key_id` | String | AWS access key ID |
| `aws_secret_access_key` | String | AWS secret access key |
| `aws_session_token` | String | AWS session token |
| `aws_default_region` | String | AWS default region. Defaults to `us-east-1` |
| `aws_resource_identifier` | String | Set to override the AWS resource identifier for the deployment. Defaults to `${GITHUB_ORG_NAME}-${GITHUB_REPO_NAME}-${GITHUB_BRANCH_NAME}`. |
| `aws_additional_tags` | JSON | Add additional tags to the terraform [default tags](https://www.hashicorp.com/blog/default-tags-in-the-terraform-aws-provider), any tags put here will be added to all provisioned resources. |
<hr/>
<br/>

#### **Secrets and Environment Variables Inputs**
| Name             | Type    | Description - Check note about [**environment variables**](#environment-variables). |
|------------------|---------|------------------------------------|
| `env_aws_secret` | String | Secret name to pull environment variables from AWS Secret Manager. Accepts comma separated list of secrets. |
| `env_repo` | String | `.env` file containing environment variables to be used with the app. Name defaults to `repo_env`. |
| `env_ghs` | String | `.env` file to be used with the app. This is the name of the [Github secret](https://docs.github.com/es/actions/security-guides/encrypted-secrets). |
| `env_ghv` | String | `.env` file to be used with the app. This is the name of the [Github variables](https://docs.github.com/en/actions/learn-github-actions/variables). |
<hr/>
<br/>

#### **EC2 Inputs**
| Name             | Type    | Description                        |
|------------------|---------|------------------------------------|
| `aws_ec2_instance_create` | Boolean | Toggles the creation of an EC2 instance. |
| `aws_ec2_ami_filter` | String | AWS AMI Filter string. Will be used to lookup for lates image based on the string. Defaults to `ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*`.' |
| `aws_ec2_ami_owner` | String | Owner of AWS AMI image. This ensures the provider is the one we are looking for. Defaults to `099720109477`, Canonical (Ubuntu). |
| `aws_ec2_ami_id` | String | AWS AMI ID. Will default to the latest Ubuntu 22.04 server image (HVM). Accepts `ami-###` values. |
| `aws_ec2_ami_update` | Boolean | Set this to `true` if you want to recreate the EC2 instance if there is a newer version of the AMI. Defaults to `false`.|
| `aws_ec2_instance_type` | String | The AWS IAM instance type to use. Default is `t2.small`. See [this list](https://aws.amazon.com/ec2/instance-types/) for reference. |
| `aws_ec2_instance_root_vol_size` | Integer | Define the volume size (in GiB) for the root volume on the AWS Instance. Defaults to `8`. | 
| `aws_ec2_instance_root_vol_preserve` | Boolean | Set this to true to avoid deletion of root volume on termination. Defaults to `false`. | 
| `aws_ec2_security_group_name` | String | The name of the EC2 security group. Defaults to `SG for ${aws_resource_identifier} - EC2`. |
| `aws_ec2_iam_instance_profile` | String | The AWS IAM instance profile to use for the EC2 instance. Will create one if none provided with the name `aws_resource_identifier`. |
| `aws_ec2_create_keypair_sm` | Boolean | Generates and manages a secret manager entry that contains the public and private keys created for the ec2 instance. |
| `aws_ec2_instance_public_ip` | Boolean | Add a public IP to the instance or not. (Not an Elastic IP). |
| `aws_ec2_port_list` | String | Comma separated list of ports to be enabled in the EC2 instance security group. (NOT THE ELB) In a `80,443` format. Port `22` is enabled as default to allow Ansible connection. |
| `aws_ec2_user_data_file` | String | Relative path in the repo for a user provided script to be executed with Terraform EC2 Instance creation. See [this note](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/user-data.html#user-data-shell-scripts). Make sure the add the executable flag to the file. |
| `aws_ec2_user_data_replace_on_change`| Boolean | If `aws_ec2_user_data_file` file changes, instance will stop and start. Hence public IP will change. This will destroy and recreate the instance. Defaults to `true`. |
| `aws_ec2_additional_tags` | JSON | Add additional tags to the terraform [default tags](https://www.hashicorp.com/blog/default-tags-in-the-terraform-aws-provider), any tags put here will be added to ec2 provisioned resources.|
<hr/>
<br/>

#### **VPC Inputs**
| Name             | Type    | Description                        |
|------------------|---------|------------------------------------|
| `aws_vpc_create` | Boolean | Define if a VPC should be created. Defaults to `false`. |
| `aws_vpc_name` | String | Define a name for the VPC. Defaults to `VPC for ${aws_resource_identifier}`. |
| `aws_vpc_cidr_block` | String | Define Base CIDR block which is divided into subnet CIDR blocks. Defaults to `10.0.0.0/16`. |
| `aws_vpc_public_subnets` | String | Comma separated list of public subnets. Defaults to `10.10.110.0/24`|
| `aws_vpc_private_subnets` | String | Comma separated list of private subnets. If no input, no private subnet will be created. Defaults to `<none>`. |
| `aws_vpc_availability_zones` | String | Comma separated list of availability zones. Defaults to `aws_default_region+<random>` value. If a list is defined, the first zone will be the one used for the EC2 instance. |
| `aws_vpc_id` | String | **Existing** AWS VPC ID to use. Accepts `vpc-###` values. |
| `aws_vpc_subnet_id` | String | **Existing** AWS VPC Subnet ID. If none provided, will pick one. (Ideal when there's only one). |
| `aws_vpc_enable_nat_gateway` | Boolean | Adds a NAT gateway for each public subnet. Defaults to `false`. |
| `aws_vpc_single_nat_gateway` | Boolean | Toggles only one NAT gateway for all of the public subnets. Defaults to `false`. |
| `aws_vpc_external_nat_ip_ids` | String | **Existing** comma separated list of IP IDs if reusing. (ElasticIPs). |
| `aws_vpc_additional_tags` | JSON | Add additional tags to the terraform [default tags](https://www.hashicorp.com/blog/default-tags-in-the-terraform-aws-provider), any tags put here will be added to vpc provisioned resources.|
<hr/>
<br/>

#### **AWS Route53 Domains and Certificate Inputss**
| Name             | Type    | Description                        |
|------------------|---------|------------------------------------|
| `aws_r53_enable` | Boolean | Set this to true if you wish to use an existing AWS Route53 domain. **See note**. Default is `false`. |
| `aws_r53_domain_name` | String | Define the root domain name for the application. e.g. bitovi.com'. |
| `aws_r53_sub_domain_name` | String | Define the sub-domain part of the URL. Defaults to `aws_resource_identifier`. |
| `aws_r53_root_domain_deploy` | Boolean | Deploy application to root domain. Will create root and www records. Default is `false`. |
| `aws_r53_enable_cert` | Boolean | Set this to true if you wish to manage certificates through AWS Certificate Manager with Terraform. **See note**. Default is `false`. | 
| `aws_r53_cert_arn` | String | Define the certificate ARN to use for the application. **See note**. |
| `aws_r53_create_root_cert` | Boolean | Generates and manage the root cert for the application. **See note**. Default is `false`. |
| `aws_r53_create_sub_cert` | Boolean | Generates and manage the sub-domain certificate for the application. **See note**. Default is `false`. |
| `aws_r53_additional_tags` | JSON | Add additional tags to the terraform [default tags](https://www.hashicorp.com/blog/default-tags-in-the-terraform-aws-provider), any tags put here will be added to R53 provisioned resources.|
<hr/>
<br/>

#### **Load Balancer Inputs**
| Name             | Type    | Description                        |
|------------------|---------|------------------------------------|
| `aws_elb_create` | Boolean | Toggles the creation of a load balancer and map ports to the EC2 instance. Defaults to `false`.|
| `aws_elb_security_group_name` | String | The name of the ELB security group. Defaults to `SG for ${aws_resource_identifier} - ELB`. |
| `aws_elb_app_port` | String | Port in the EC2 instance to be redirected to. Default is `3000`. Accepts comma separated values like `3000,3001`. | 
| `aws_elb_app_protocol` | String | Protocol to enable. Could be HTTP, HTTPS, TCP or SSL. Defaults to `TCP`. If length doesn't match, will use `TCP` for all.|
| `aws_elb_listen_port` | String | Load balancer listening port. Default is `80` if NO FQDN provided, `443` if FQDN provided. Accepts comma separated values. |
| `aws_elb_listen_protocol` | String | Protocol to enable. Could be HTTP, HTTPS, TCP or SSL. Defaults to `TCP` if NO FQDN provided, `SSL` if FQDN provided. |
| `aws_elb_healthcheck` | String | Load balancer health check string. Default is `TCP:22`. |
| `aws_elb_access_log_bucket_name` | String | S3 bucket name to store the ELB access logs. Defaults to `${aws_resource_identifier}-logs` (or `-lg `depending of length). **Bucket will be deleted if stack is destroyed.** | 
| `aws_elb_access_log_expire` | String | Delete the access logs after this amount of days. Defaults to `90`. Set to `0` in order to disable this policy. | 
| `aws_elb_additional_tags` | JSON | Add additional tags to the terraform [default tags](https://www.hashicorp.com/blog/default-tags-in-the-terraform-aws-provider), any tags put here will be added to elb provisioned resources.|
<hr/>
<br/>

#### **WAF**
| Name             | Type    | Description                        |
|------------------|---------|------------------------------------|
| `aws_waf_enable` | Boolean | Enable WAF for load balancer (LB only - NOT ELB). Default is `false` |
| `aws_waf_logging_enable`| Boolean | Enable WAF logging to CloudWatch. Default `false` |
| `aws_waf_log_retention_days`| Number | CloudWatch log retention period for WAF logs. Default `30` |
| `aws_waf_rule_rate_limit`| String | Rate limit for WAF rules. Default is `2000` |
| `aws_waf_rule_managed_rules`| Boolean | Enable common managed rule groups to use. Default `false` |
| `aws_waf_rule_managed_bad_inputs`| Boolean | Enable managed rule for bad inputs. Default `false` |
| `aws_waf_rule_ip_reputation`| Boolean | Enable managed rule for IP reputation. Default `false` |
| `aws_waf_rule_anonymous_ip`| Boolean | Enable managed rule for anonymous IP. Default `false` |
| `aws_waf_rule_bot_control`| Boolean | Enable managed rule for bot control (costs extra). Default `false` |
| `aws_waf_rule_geo_block_countries`| String | Comma separated list of countries to block. |
| `aws_waf_rule_geo_allow_only_countries`| String | Comma separated list of countries to allow. |
| `aws_waf_rule_sqli`| Boolean | Enable managed rule for SQL injection. Default `false` |
| `aws_waf_rule_linux`| Boolean | Enable managed rule for Linux. Default `false` |
| `aws_waf_rule_unix`| Boolean | Enable managed rule for Unix. Default `false` |
| `aws_waf_rule_admin_protection`| Boolean | Enable managed rule for admin protection. Default `false` |
| `aws_waf_rule_user_arn`| String | String of the user created ARN set of rules. |
| `aws_waf_additional_tags`| String | A list of strings that will be added to created resources. Default `"{}"` |
<hr/>
<br/>

#### **EFS Inputs**
| Name             | Type    | Descrifption                        |
|------------------|---------|------------------------------------|
| `aws_efs_create` | Boolean | Toggle to indicate whether to create an EFS volume and mount it to the EC2 instance as a part of the provisioning. Note: The stack will manage the EFS and will be destroyed along with the stack. |
| `aws_efs_fs_id` | String | ID of existing EFS volume if you wish to use an existing one. |
| `aws_efs_create_mount_target` | String | Toggle to indicate whether we should create a mount target for the EFS volume or not. Defaults to `true`.|
| `aws_efs_create_ha` | Boolean | Toggle to indicate whether the EFS resource should be highly available (mount points in all available zones within region). |
| `aws_efs_vol_encrypted` | String | Toggle encryption of the EFS volume. Defaults to `true`.|
| `aws_efs_kms_key_id` | String | The ARN for the KMS encryption key. Will use default if none defined. |
| `aws_efs_performance_mode` | String | Toggle perfomance mode. Options are: `generalPurpose` or `maxIO`.|  
| `aws_efs_throughput_mode` | String | Throughput mode for the file system. Defaults to `bursting`. Valid values: `bursting`, `provisioned`, or `elastic`. When using provisioned, also set `aws_efs_throughput_speed`. |
| `aws_efs_throughput_speed` | String | The throughput, measured in MiB/s, that you want to provision for the file system. Only applicable with throughput_mode set to provisioned. |
| `aws_efs_security_group_name` | String | The name of the EFS security group. Defaults to `SG for ${aws_resource_identifier} - EFS`. |
| `aws_efs_allowed_security_groups` | String | Extra names of the security grou-ps to access the EFS volume. Accepts comma separated list of. |
| `aws_efs_ingress_allow_all` | Boolean | Allow access from 0.0.0.0/0 in the same VPC. Defaults to `true`. |
| `aws_efs_create_replica` | Boolean | Toggle whether a read-only replica should be created for the EFS primary file system. |
| `aws_efs_replication_destination` | String | AWS Region to target for replication. |
| `aws_efs_enable_backup_policy` | Boolean | Toggle whether the EFS should have a backup policy. |
| `aws_efs_transition_to_inactive` | String | Indicates how long it takes to transition files to the IA storage class. Defaults to `AFTER_30_DAYS`. |
| `aws_efs_mount_target` | String | Directory path in efs to mount directory to. Default is `/`. |
| `aws_efs_ec2_mount_point` | String | The `aws_efs_ec2_mount_point` input represents the folder path within the EC2 instance to the data directory. Default is `/user/ubuntu/<application_repo>/data`. Additionally, this value is loaded into the docker-compose `.env` file as `HOST_DIR`. |
| `aws_efs_additional_tags` | JSON | Add additional tags to the terraform [default tags](https://www.hashicorp.com/blog/default-tags-in-the-terraform-aws-provider), any tags put here will be added to efs provisioned resources.|
<hr/>
<br/>

#### **RDS Inputs**
| Name             | Type    | Description                        |
|------------------|---------|------------------------------------|
| `aws_rds_db_enable`| Boolean | Toggles the creation of a RDS DB. Defaults to `false`. |
| `aws_rds_db_proxy`| Boolean | Set to `true` to add a RDS DB Proxy. |
| `aws_rds_db_identifier`| String | Database identifier that will appear in the AWS Console. Defaults to `aws_resource_identifier` if none set. |
| `aws_rds_db_name`| String | The name of the database to create when the DB instance is created. If this parameter is not specified, no database is created in the DB instance. |
| `aws_rds_db_user`| String | Username for the database. Defaults to `dbuser`. |
| `aws_rds_db_engine`| String | Which Database engine to use. Defaults to `postgres`. |
| `aws_rds_db_engine_version`| String | Which Database engine version to use. Will use latest if none defined. |
| `aws_rds_db_ca_cert_identifier`| String | Defines the certificate to use with the instance. Defaults to `rds-ca-ecc384-g1`.|
| `aws_rds_db_security_group_name`| String | The name of the database security group. Defaults to `SG for ${aws_resource_identifier} - RDS`. |
| `aws_rds_db_allowed_security_groups` | String | Comma separated list of security groups to add to the DB Security Group. (Allowing incoming traffic.) | 
| `aws_rds_db_ingress_allow_all` | Boolean | Allow incoming traffic from 0.0.0.0/0. Defaults to `true`. |
| `aws_rds_db_publicly_accessible` | Boolean | Allow the database to be publicly accessible from the internet. Defaults to `false`. |
| `aws_rds_db_port`| String | Port where the DB listens to. |
| `aws_rds_db_subnets`| String | Specify which subnets to use as a list of strings.  Example: `i-1234,i-5678,i-9101`. |
| `aws_rds_db_allocated_storage`| String | Storage size. Defaults to `10`. |
| `aws_rds_db_max_allocated_storage`| String | Max storage size. Defaults to `0` to disable auto-scaling. |
| `aws_rds_db_storage_encrypted` | Boolean | Toogle storage encryption. Defatuls to false. |
| `aws_rds_db_storage_type` | String | Storage type. Like gp2 / gp3. Defaults to gp2. |
| `aws_rds_db_kms_key_id` | String | The ARN for the KMS encryption key. |
| `aws_rds_db_instance_class`| String | DB instance server type. Defaults to `db.t3.micro`. See [this list](https://aws.amazon.com/rds/instance-types/). |
| `aws_rds_db_final_snapshot` | String | If final snapshot is wanted, add a snapshot name. Leave emtpy if not. |
| `aws_rds_db_restore_snapshot_identifier` | String | Name of the snapshot to restore the databse from. |
| `aws_rds_db_cloudwatch_logs_exports`| String | Set of log types to enable for exporting to CloudWatch logs. Defaults to `postgresql`. Options are MySQL and MariaDB: `audit,error,general,slowquery`. PostgreSQL: `postgresql,upgrade`. MSSQL: `agent,error`. Oracle: `alert,audit,listener,trace`. |
| `aws_rds_db_multi_az` | Boolean| Specifies if the RDS instance is multi-AZ. Defaults to `false`. |
| `aws_rds_db_maintenance_window` | String | The window to perform maintenance in. Eg: `Mon:00:00-Mon:03:00` |
| `aws_rds_db_apply_immediately` | Boolean | Specifies whether any database modifications are applied immediately, or during the next maintenance window. Defaults to `false`.|
| `aws_rds_db_performance_insights_enable` | Boolean | Enables performance insights for the database. Defaults to `false`. |
| `aws_rds_db_performance_insights_retention` | String | KMS key ID to use for encrypting performance insights data. |
| `aws_rds_db_performance_insights_kms_key_id` | String | Number of days to retain performance insights data. Defaults to `7`. |
| `aws_rds_db_monitoring_interval` | String | The interval, in seconds, between points when metrics are collected. Defaults to `0` (disabled). Valid values are `0,1,5,10,15,30,60`. |
| `aws_rds_db_monitoring_role_arn` | String | The ARN of the IAM role that provides access to the Enhanced Monitoring metrics. |
| `aws_rds_db_insights_mode` | String | The mode for Performance Insights. Could be `standard` (default) or `advanced`. |
| `aws_rds_db_allow_major_version_upgrade` | Boolean | Indicates that major version upgrades are allowed. Defaults to `false`. |
| `aws_rds_db_auto_minor_version_upgrade` | Boolean | Indicates that minor version upgrades are allowed. Defaults to `true`. |
| `aws_rds_db_backup_retention_period` | String | The number of days to retain backups for. Must be between 0 (disabled) and 35. Defaults to `0`. |
| `aws_rds_db_backup_window` | String | The window during which backups are taken. Eg: `"09:46-10:16"`. |
| `aws_rds_db_copy_tags_to_snapshot` | Boolean | Indicates whether to copy tags to snapshots. Defaults to `false`. |
| `aws_rds_db_additional_tags` | JSON | Add additional tags to the terraform [default tags](https://www.hashicorp.com/blog/default-tags-in-the-terraform-aws-provider), any tags put here will be added to RDS provisioned resources.|
<hr/>
<br/>

#### **Aurora Inputs**
| Name             | Type    | Description                        |
|------------------|---------|------------------------------------|
| `aws_aurora_enable` | Boolean | Toggles deployment of an Aurora database. Defaults to `false`. |
| `aws_aurora_proxy` | Boolean | Aurora DB Proxy Toggle. Defaults to `false`. |
| `aws_aurora_cluster_name` | String | The name of the cluster. Defaults to `aws_resource_identifier` if none set. |
| `aws_aurora_engine` | String | The database engine to use. Defaults to `aurora-postgresql`. |
| `aws_aurora_engine_version` | String | The DB version of the engine to use. Will default to one of the latest selected by AWS. More information [Postgres](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/AuroraPostgreSQL.Updates.20180305.html) or [MySQL](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraMySQLReleaseNotes/Welcome.html)|
| `aws_aurora_engine_mode` | String | Database engine mode. Could be global, multimaster, parallelquey, provisioned, serverless. |
| `aws_aurora_availability_zones` | String | Comma separated list of zones to deploy DB to. If none, will automatically set this. | 
| `aws_aurora_cluster_apply_immediately` | Boolean | Apply changes immediately to the cluster. If not, will be done in next maintenance window. Defaults to `false`. |
| **Storage** |||
| `aws_aurora_allocated_storage` | String | Amount of storage in gigabytes. Required for multi-az cluster. |
| `aws_aurora_storage_encrypted` | Boolean | Toggles whether the DB cluster is encrypted. Defaults to `true`. |
| `aws_aurora_kms_key_id` | String | KMS Key ID to use with the cluster encrypted storage. |
| `aws_aurora_storage_type` | String | Define type of storage to use. Required for multi-az cluster. |
| `aws_aurora_storage_iops` | String | iops for storage. Required for multi-az cluster. | 
| **Cluster details** |||
| `aws_aurora_database_name` | String | The name of the database. will be created if it does not exist. Defaults to `aurora`. |
| `aws_aurora_master_username` | String | Master username. Defaults to `aurora`. |
| `aws_aurora_database_group_family` | String | The family of the DB parameter group. See [MySQL Reference](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/AuroraMySQL.Reference.html) or [Postgres Reference](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/AuroraPostgreSQL.Reference.html). Defaults automatically set for MySQL(`aurora-mysql8.0`) and Postgres (`aurora-postgresql15`). |
| `aws_aurora_iam_auth_enabled` | Boolean | Toggles IAM Authentication. Defaults to `false`. |
| `aws_aurora_iam_roles` | String | Define the ARN list of allowed roles. |
| `aws_aurora_cluster_db_instance_class` | String | To create a Multi-AZ RDS cluster, you must additionally specify the engine, storage_type, allocated_storage, iops and aws_aurora_db_cluster_instance_class attributes. |
| **Networking** |||
| `aws_aurora_security_group_name` | String | Name of the security group to use for postgres. Defaults to `SG for {aws_resource_identifier} - Aurora`.| 
| `aws_aurora_allowed_security_groups` | String | Extra names of the security groups to access Aurora. Accepts comma separated list of. |
| `aws_aurora_ingress_allow_all` | Boolean | Allow access from 0.0.0.0/0 in the same VPC. Defaults to `true`. |
| `aws_aurora_subnets` | String | Subnet ids to use for postgres. Accepts comma separated list of. |
| `aws_aurora_database_port` | String | Database port. Defaults to `5432`. |
| **Backup & maint** |||
| `aws_aurora_cloudwatch_enable` | Boolean | Toggles cloudwatch. Defaults to `true`. |
| `aws_aurora_cloudwatch_log_type` | String | Comma separated list of log types to include in cloudwatch. If none defined, will use [postgresql] or [audit,error,general,slowquery]. Based on the db engine. |
| `aws_aurora_cloudwatch_retention_days` | String | Days to store cloudwatch logs. Defaults to `7`. |
| `aws_aurora_backtrack_window` | String | Target backtrack window, in seconds. Only available for aurora and aurora-mysql engines currently. 0 to disable. Defaults to `0`. |
| `aws_aurora_backup_retention_period` | String | Days to retain backups for. Defaults to `5`. |
| `aws_aurora_backup_window` | String | Daily time range during which the backups happen. |
| `aws_aurora_maintenance_window` | String | Maintenance window. |
| `aws_aurora_database_final_snapshot` | String | Set the name to generate a snapshot of the database before deletion. |
| `aws_aurora_deletion_protection` | Boolean | Protects the database from deletion. Defaults to `false`.  **This won't prevent db instances to be deleted.** |
| `aws_aurora_delete_auto_backups` | Boolean | Specifies whether to remove automated backups immediately after the DB cluster is deleted. Default is `true`. |
| `aws_aurora_restore_snapshot_id` | String | Restore an initial snapshot of the DB if specified. |
| `aws_aurora_restore_to_point_in_time` | map{String} | Restore database to a point in time. Will require a map of strings. Like `{"restore_to_time"="W","restore_type"="X","source_cluster_identifier"="Y", "use_latest_restorable_time"="Z"}`. Default `{}`. |
| `aws_aurora_snapshot_name` | String | Takes a snapshot of the DB. This is treated as one resource, meaning only one can be created, even if name changes.|
| `aws_aurora_snapshot_overwrite` | Boolean | Takes a snapshot of the DB deleteing the previous snapshot. Defaults to `false`. |
| **DB Instance** |||
| `aws_aurora_db_instances_count` | String | Amount of instances to create. Defaults to `1`. |
| `aws_aurora_db_instance_class` | String | Database instance size. Defaults to `db.r6g.large`. |
| `aws_aurora_db_apply_immediately` | String | Specifies whether any modifications are applied immediately, or during the next maintenance window. Defaults to `false`. |
| `aws_aurora_db_ca_cert_identifier` | String | Certificate to use with the database. Defaults to `rds-ca-ecc384-g1`. |
| `aws_aurora_db_maintenance_window` | String | Maintenance window. |
| `aws_aurora_db_publicly_accessible` | Boolean | Make database publicly accessible. Defaults to `false`. | 
| `aws_aurora_performance_insights_enable`| Boolean | Enables performance insights for the database. Defaults to false. |
| `aws_aurora_performance_insights_kms_key_id`| String | KMS key ID to use for encrypting performance insights data. |
| `aws_aurora_performance_insights_retention`| String | Number of days to retain performance insights data. Defaults to 7. |
| `aws_aurora_additional_tags` | JSON | A JSON object of additional tags that will be included on created resources. Example: `{"key1": "value1", "key2": "value2"}`. |
<hr/>
<br/>

#### **DB Proxy Inputs**
| Name             | Type    | Description                        |
|------------------|---------|------------------------------------|
| `aws_db_proxy_enable` | Boolean | Set to `true` to enable a database proxy. |
| `aws_db_proxy_name` | String | Name of the database proxy.  Defaults to `aws_resource_identifier` |
| `aws_db_proxy_database_id` | String |  Specify the ID of the databse to use. |
| `aws_db_proxy_cluster` | Boolean | Set to true if you are creating this for an RDS Cluster. Defaults to `false`. |
| `aws_db_proxy_secret_name` | String | AWS Secrets manager containing database details and credentials. | 
| `aws_db_proxy_client_password_auth_type` | String | Overrides auth type. Using `MYSQL_NATIVE_PASSWORD`, `POSTGRES_SCRAM_SHA_256`, and `SQL_SERVER_AUTHENTICATION` depending on the database family. |
| `aws_db_proxy_tls` | Boolean | Make TLS a requirement for connections. Defaults to `true`.|
| `aws_db_proxy_security_group_name` | String | Name for the proxy security group. Defaults to `aws_resource_identifier`. |
| `aws_db_proxy_database_security_group_allow` | Boolean | If true, will add an incoming rule from every security group associated with the DB. |
| `aws_db_proxy_allowed_security_group` | String | Comma separated list for extra allowed security groups.|
| `aws_db_proxy_allow_all_incoming` | Boolean | Allow all incoming traffic to the DB Proxy (0.0.0.0/0 rule). Keep in mind that the proxy is only available from the internal network except manually exposed. | 
| `aws_db_proxy_cloudwatch_enable` | Boolean | Toggle Cloudwatch logs. Will be stored in `/aws/rds/proxy/rds_proxy.name`. |
| `aws_db_proxy_cloudwatch_retention_days` | String | Number of days to retain cloudwatch logs. Defaults to `14`. |
| `aws_db_proxy_additional_tags` | JSON | Add additional tags to the ter added to aurora provisioned resources.|
<hr/>
<br/>

#### **Docker Inputs**
| Name             | Type    | Description                        |
|------------------|---------|------------------------------------|
| `docker_install` | Boolean | Toggle docker installation through Ansible. `docker-compose up` will be excecuted after. |
| `docker_remove_orphans` | Boolean | Set to `true` to turn the `--remove-orphans` flag. Defaults to `false`. |
| `docker_full_cleanup` | Boolean | Set to `true` to run `docker-compose down` and `docker system prune --all --force --volumes` after. Runs before `docker_install`. WARNING: docker volumes will be destroyed. |
| `docker_repo_app_directory` | String | Relative path for the directory of the app. (i.e. where the `docker-compose.yaml` file is located). This is the directory that is copied into the EC2 instance. Default is `/`, the root of the repository. Add a `.gha-ignore` file with a list of files to be exluded. (Using glob patterns). |
| `docker_repo_app_directory_cleanup` | Boolean | Will generate a timestamped compressed file (in the home directory of the instance) and delete the app repo directory. Runs before `docker_install` and after `docker_full_cleanup`. |
| `docker_efs_mount_target` | String | Directory path within docker env to mount directory to. Default is `/data`|
| `docker_cloudwatch_enable` | Boolean | Toggle cloudwatch creation for Docker. Create a file named `docker-daemon.json` in your repo root dir if you need to customize it. Defaults to `false`. Check [docker docs](https://docs.docker.com/config/containers/logging/awslogs/).|
| `docker_cloudwatch_lg_name` | String| Log group name. Will default to `${aws_resource_identifier}-docker-logs` if none. |
| `docker_cloudwatch_skip_destroy` | Boolean | Toggle deletion or not when destroying the stack. Defaults to `false`. |
| `docker_cloudwatch_retention_days` | String | Number of days to retain logs. 0 to never expire. Defaults to `14`. See [note](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group#retention_in_days). |
<hr/>
<br/>

#### **Redis Inputs**
| Name             | Type    | Description                        |
|------------------|---------|------------------------------------|
| `aws_redis_enable` | Boolean | Enables the creation of a Redis instance. |
| `aws_redis_user` | String | Redis username. Defaults to `redisuser`. |
| `aws_redis_user_access_string` | String | String expression for user access. Defaults to `on ~* +@all`. |
| `aws_redis_user_group_name` | String | User group name. Defaults to `aws_resource_identifier-redis`. |
| `aws_redis_security_group_name` | String | Redis security group name. Defaults to `SG for aws_resource_identifier - Redis`. |
| `aws_redis_ingress_allow_all` | Boolean | Allow access from 0.0.0.0/0. Defaults to `true`. |
| `aws_redis_allowed_security_groups` | String | Comma separated list of security groups to be added to the Redis SG. |
| `aws_redis_subnets` | String | Define a list of specific subnets where Redis will live. Defaults to all of the VPC ones. If nome defined, default VPC. |
| `aws_redis_port` | String | Redis port. Defaults to `6379`. |
| `aws_redis_at_rest_encryption` | Boolean | Encryption at rest. Defaults to `true`. |
| `aws_redis_in_transit_encryption` | Boolean | In-transit encryption. Defaults to `true`. |
| `aws_redis_replication_group_id` | String | Name of the Redis replication group. Defaults to `aws_resource_identifier-redis`. |
| `aws_redis_node_type` | String | Node type of the Redis instance. Defaults to `cache.t2.small`. |
| `aws_redis_num_cache_clusters` | String | Amount of Redis nodes. Defaults to `1`. |
| `aws_redis_parameter_group_name` | String | Redis parameters groups name. If cluster wanted, set it to something that includes *.cluster.on.* Defaults to `default.redis7`. |
| `aws_redis_num_node_groups` | String | Number of node groups. Defaults to `0`. |
| `aws_redis_replicas_per_node_group` | String | Number of replicas per node group. Defaults to `0`. |
| `aws_redis_multi_az_enabled` | Boolean | Enables multi-availability-zone redis. Defaults to `false`. |
| `aws_redis_automatic_failover` | Boolean | Allows overriding the automatic configuration of this value, only needed when playing with resources in a non-conventional way. |
| `aws_redis_apply_immediately` | Boolean | Specifies whether any modifications are applied immediately, or during the next maintenance window. Defaults to `false`. |
| `aws_redis_auto_minor_upgrade` | Boolean | Specifies whether minor version engine upgrades will be applied automatically to the underlying Cache Cluster instances during the maintenance window. Defaults to `true`. |
| `aws_redis_maintenance_window` | String | Specifies the weekly time range for when maintenance on the cache cluster is performed. Example:`sun:05:00-sun:06:00`. Defaults to `null`. |
| `aws_redis_snapshot_window` | String | Daily time range (in UTC) when to start taking a daily snapshot. Minimum is a 60 minute period. Example: `05:00-09:00`. Defaults to `null`. |
| `aws_redis_final_snapshot` | String | Change name to define a final snapshot. |
| `aws_redis_snapshot_restore_name` | String | Set name to restore a snapshot to the cluster. The default behaviour is to restore it each time this action runs. |
| `aws_redis_cloudwatch_enabled` | String | Enable or disables Cloudwatch logging. |
| `aws_redis_cloudwatch_lg_name` | String | Cloudwatch log group name. Defaults to `/aws/redis/aws_resource_identifier` **Will append log_type to it** eg. `/your/name/slow-log`. |
| `aws_redis_cloudwatch_log_format` | String | Define log format between `json`(default) and text. |
| `aws_redis_cloudwatch_log_type` | String | Log type. Older Redis engines need `slow-log`. Newer support `engine-log` (default). You could add both by setting `slow-log,engine-log`.  |
| `aws_redis_cloudwatch_retention_days` | String | Number of days to retain cloudwatch logs. Defaults to `14`. |
| `aws_redis_single_line_url_secret`| Boolean | Creates an AWS secret containing the connection string containing `protocol://user@pass:endpoint:port` |
| `aws_redis_additional_tags` | String | Additional tags to be added to every Redis related resource. |
<hr/>
<br/>

#### **ECS Inputs***
| Name             | Type    | Description                        |
|------------------|---------|------------------------------------|
| `aws_ecs_enable`| Boolean | Toggle ECS Creation. Defaults to `false`. |
| `aws_ecs_service_name`| String | Elastic Container Service name. |
| `aws_ecs_cluster_name`| String | Elastic Container Service cluster name. |
| `aws_ecs_service_launch_type`| String | Configuration type. Could be `EC2`, `FARGATE` or `EXTERNAL`. Defaults to `FARGATE`. |
| `aws_ecs_task_type`| String | Configuration type. Could be `EC2`, `FARGATE` or empty. Will default to `aws_ecs_service_launch_type` if none defined. (Blank if `EXTERNAL`). |
| `aws_ecs_task_name`| String | Elastic Container Service task name. If task is defined with a JSON file, should be the same as the container name. |
| `aws_ecs_task_ignore_definition`| Boolean | Toggle to ignore task definition changes after first deployment. Useful when using external tools to manage the task definition. Default: `false`. |
| `aws_ecs_task_execution_role`| String | Elastic Container Service task execution role name from IAM. Defaults to `ecsTaskExecutionRole`. |
| `aws_ecs_task_json_definition_file`| String | Name of the json file containing task definition. Overrides every other input. |
| `aws_ecs_task_network_mode`| String | Network type to use in task definition. One of `none`, `bridge`, `awsvpc`, and `host`. |
| `aws_ecs_task_cpu`| String | Task CPU Amount. |
| `aws_ecs_task_mem`| String | Task Mem Amount. |
| `aws_ecs_container_cpu`| String | Container CPU Amount. |
| `aws_ecs_container_mem`| String | Container Mem Amount. |
| `aws_ecs_node_count`| String | Node count for ECS Cluster. |
| `aws_ecs_app_image`| String | Name of the container image to be used. |
| `aws_ecs_security_group_name`| String | ECS Secruity group name. |
| `aws_ecs_assign_public_ip`| Boolean | Assign public IP to node. |
| `aws_ecs_container_port`| String | Comma separated list of container ports. One for each. |
| `aws_ecs_lb_port`| String | Comma serparated list of ports exposed by the load balancer. One for each. |
| `aws_ecs_lb_redirect_enable`| String | Toggle redirect from HTTP and/or HTTPS to the main port. |
| `aws_ecs_lb_container_path`| String | Comma separated list of paths for subsequent deployed containers. Need `aws_ecs_lb_redirect_enable` to be true. eg. api. (For http://bitovi.com/api/). If you have multiple, set them to `api,monitor,prom,,` (This example is for 6 containers) |
| `aws_ecs_lb_ssl_policy` | String | SSL Policy for HTTPS listener in ALB. Will default to ELBSecurityPolicy-TLS13-1-2-2021-06 if none provided. See [this link](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/create-https-listener.html) for other policies. |
| `aws_ecs_autoscaling_enable`| Boolean | Toggle ecs autoscaling policy. |
| `aws_ecs_autoscaling_max_nodes`| String | Max ammount of nodes to scale up to. |
| `aws_ecs_autoscaling_min_nodes`| String | Min ammount of nodes to scale down to. |
| `aws_ecs_autoscaling_max_mem`| String | Define autoscaling max mem. |
| `aws_ecs_autoscaling_max_cpu`| String | Define autoscaling max cpu. |
| `aws_ecs_cloudwatch_enable`| Boolean | Toggle cloudwatch for ECS. Default `false`. |
| `aws_ecs_cloudwatch_lg_name`| String | Log group name. Will default to `aws_identifier` if none. |
| `aws_ecs_cloudwatch_skip_destroy`| Boolean | Toggle deletion or not when destroying the stack. |
| `aws_ecs_cloudwatch_retention_days`| String | Number of days to retain logs. 0 to never expire. Defaults to `14`. |
| `aws_ecs_additional_tags`| JSON | Add additional tags to the terraform [default tags](https://www.hashicorp.com/blog/default-tags-in-the-terraform-aws-provider), any tags put here will be added to ECS provisioned resources.|
<hr/>
<br/>

#### **ECR Inputs**
| Name             | Type    | Description                        |
|------------------|---------|------------------------------------|
| `aws_ecr_repo_create` | Boolean | Determines whether a repository will be created.' |
| `aws_ecr_repo_type` | String | The type of repository to create. Either `public` or `private`. Defaults to `private`.' |
| `aws_ecr_repo_name` | String | The name of the repository. If none, will use the default resource-identifier.' |
| `aws_ecr_repo_mutable` | Boolean | The tag mutability setting for the repository. Set this to true if `MUTABLE`. Defaults to false, so `IMMUTABLE`' |
| `aws_ecr_repo_encryption_type` | String | The encryption type for the repository. Must be one of: `KMS` or `AES256`. Defaults to `AES256`' |
| `aws_ecr_repo_encryption_key_arn` | String | The ARN of the KMS key to use when encryption_type is `KMS`. If not specified, uses the default AWS managed key for ECR. |
| `aws_ecr_repo_force_destroy` | Boolean | If `true`, will delete the repository even if it contains images. Defaults to `false`' |
| `aws_ecr_repo_image_scan` | Boolean | Indicates whether images are scanned after being pushed to the repository (`true`) (default) or not scanned (`false`)' |
| `aws_ecr_registry_scan_rule` | String | One or multiple blocks specifying scanning rules to determine which repository filters are used and at what frequency. Defaults to `[]`.  |
| `aws_ecr_registry_pull_through_cache_rules` | String | List of pull through cache rules to create. Use map(map(string)). ' |
| `aws_ecr_registry_scan_config` | String | Scanning type to set for the registry. Can be either `ENHANCED` or `BASIC`. Defaults to null.' |
| `aws_ecr_registry_replication_rules_input` | String | The replication rules for a replication configuration. A maximum of 10 are allowed. Defaults to `[]`.' |
| `aws_ecr_repo_policy_attach` | Boolean | Determines whether a repository policy will be attached to the repository. Defaults to `true`.' |
| `aws_ecr_repo_policy_create` | Boolean | Determines whether a repository policy will be created. Defaults to `true`.' |
| `aws_ecr_repo_policy_input` | String | The JSON policy to apply to the repository. If defined overrides the default policy' |
| `aws_ecr_repo_read_arn` | String | The ARNs of the IAM users/roles that have read access to the repository. (Comma separated list)' |
| `aws_ecr_repo_write_arn` | String | The ARNs of the IAM users/roles that have read/write access to the repository. (Comma separated list)' |
| `aws_ecr_repo_read_arn_lambda` | String | The ARNs of the Lambda service roles that have read access to the repository. (Comma separated list)' |
| `aws_ecr_lifecycle_policy_input` | JSON | The policy document. This is a JSON formatted string. See more details about [Policy Parameters](http://docs.aws.amazon.com/AmazonECR/latest/userguide/LifecyclePolicies.html#lifecycle_policy_parameters) in the official AWS docs' |
| `aws_ecr_public_repo_catalog` | String | Catalog data configuration for the repository. Defaults to `{}`.' |
| `aws_ecr_registry_policy_input` | String | The policy document. This is a JSON formatted string' |
| `aws_ecr_additional_tags ` | JSON | Add additional tags to the terraform [default tags](https://www.hashicorp.com/blog/default-tags-in-the-terraform-aws-provider), any tags put here will be added to ECR provisioned resources.|
<hr/>
<br/>

#### **EKS Inputs**
| Name             | Type    | Description                        |
|------------------|---------|------------------------------------|
| `aws_eks_create` | Boolean | Define if an EKS cluster should be created |
| `aws_eks_security_group_name_cluster` | String | Define the security group name master. Defaults to `SG for ${var.aws_resource_identifier} - EKS Cluster`. |
| `aws_eks_security_group_name_node` | String | Define the security group name worker. Defaults to `SG for ${var.aws_resource_identifier} - EKS Node`. |
| `aws_eks_environment` | String | Specify the eks environment name. Defaults to `env` |
| `aws_eks_management_cidr` | String | Comma separated list of remote public CIDRs blocks to add it to Worker nodes security groups. |
| `aws_eks_allowed_ports` | String | Allow incoming traffic from this port. Accepts comma separated values, matching 1 to 1 with `aws_eks_allowed_ports_cidr`. |
| `aws_eks_allowed_ports_cidr` | String | Allow incoming traffic from this CIDR block. Accepts comma separated values, matching 1 to 1 with `aws_eks_allowed_ports`. If none defined, will allow all incoming traffic. |
| `aws_eks_cluster_name` | String | Specify the k8s cluster name. Defaults to `${var.aws_resource_identifier}-cluster` |
| `aws_eks_cluster_admin_role_arn` | String | Role ARN to gran cluster-admin permissions. | 
| `aws_eks_cluster_log_types` | String | Comma separated list of cluster log type. See [this AWS doc](https://docs.aws.amazon.com/eks/latest/userguide/control-plane-logs.html). Defaults to `api,audit,authenticator`. |
| `aws_eks_cluster_log_retention_days` | String | Days to store logs. Defaults to `7`. | 
| `aws_eks_cluster_logs_skip_destroy` | Boolean | Skip deletion of cluster logs if set to true. Defaults to `false`. |
| `aws_eks_cluster_version` | String | Specify the k8s cluster version. Defaults to `1.28` |
| `aws_eks_instance_type` | String | Define the EC2 instance type. See [this list](https://aws.amazon.com/ec2/instance-types/) for reference. Defaults to `t3a.medium`. |
| `aws_eks_instance_ami_id` | String | AWS AMI ID. Will default to the latest Amazon EKS Node image for the cluster version. |
| `aws_eks_instance_user_data_file` | String | Relative path in the repo for a user provided script to be executed with the EC2 Instance creation. See note. |
| `aws_eks_ec2_key_pair` | String | Enter an existing ec2 key pair name for worker nodes. If none, will create one. |
| `aws_eks_store_keypair_sm` | Boolean | If true, will store the newly created keys in Secret Manager. |
| `aws_eks_desired_capacity` | String | Enter the desired capacity for the worker nodes. Defaults to `2`. |
| `aws_eks_max_size` | String | Enter the max_size for the worker nodes. Defaults to `4`. |
| `aws_eks_min_size` | String | Enter the min_size for the worker nodes. Defaults to `2`. |
| `aws_eks_additional_tags` | JSON | Add additional tags to the terraform [default tags](https://www.hashicorp.com/blog/default-tags-in-the-terraform-aws-provider), any tags put here will be added to eks provisioned resources.|
| `input_helm_charts` | String | Relative path to the folder from project containing Helm charts to be installed. Could be uncompressed or compressed (.tgz) files. |
<hr/>
<br/>
<br/>

#### **Action Outputs**
| Name             | Description                        |
|------------------|------------------------------------|
| VPC |
| `aws_vpc_id` | The selected VPC ID used. |
| EC2 |
| `vm_url` | The URL of the generated app. |
| `instance_endpoint` | The URL of the generated ec2 instance. |
| `ec2_sg_id` | SG ID for the EC2 instance. |
| EFS |
| `aws_efs_fs_id` | AWS EFS FS ID of the volume. |
| `aws_efs_replica_fs_id` | AWS EFS FS ID of the replica volume. |
| `aws_efs_sg_id` | SG ID for the EFS Volume. |
| RDS |
| `db_endpoint` | RDS Endpoint. |
| `db_secret_details_name` | AWS Secret name containing db credentials. |
| `db_sg_id` | SG ID for the RDS instance. |
| `db_proxy_rds_endpoint` | Database proxy endpoint. |
| `db_proxy_secret_name_rds` | AWS Secret name containing proxy credentials. |
| `db_proxy_sg_id_rds` | SG ID for the RDS Proxy instance. |
| Aurora |
| `aurora_db_endpoint` | Aurora Endpoint. |
| `aurora_db_secret_details_name` | AWS Secret name containing db credentials. |
| `aurora_db_sg_id` | SG ID for the Aurora instance. |
| `aurora_proxy_endpoint` | Database proxy endpoint. |
| `aurora_proxy_secret_name` | AWS Secret name containing proxy credentials. |
| `aurora_proxy_sg_id` | SG ID for the RDS Proxy instance. |
| DB Proxy |
| `db_proxy_endpoint` | Database proxy endpoint. |
| `db_proxy_secret_name` | Database proxy secret_name. |
| `db_proxy_sg_id` | SG ID for the RDS Proxy instance. |
| ECS |
| `ecs_load_balancer_dns` | ECS ALB DNS Record. |
| `ecs_dns_record` | ECS DNS URL. |
| `ecs_sg_id` | ECS SG ID. |
| `ecs_lb_sg_id` | ECS LB SG ID. |
| ECR |
| `ecr_repository_arn` | ECR Repo ARN. |
| `ecr_repository_url` | ECR Repo URL. |
| REDIS |
| `redis_endpoint` | Redis Endpoint. |
| `redis_secret_name` | Redis Secret name. |
| `redis_connection_string_secret` | Redis secret containing complete URL to connect directly. (e.g. rediss://user:pass@host:port). |
| `redis_sg_id` | Redis SG ID. |
| EKS |
| `eks_cluster_name` | EKS Cluster name. |
| `eks_cluster_role_arn` | EKS Role ARN. |
<hr/>
<br/>
<br/>


## Note about resource identifiers

Most resources will contain the tag `${GITHUB_ORG_NAME}-${GITHUB_REPO_NAME}-${GITHUB_BRANCH_NAME}`, some of them, even the resource name after. 
We limit this to a 60 characters string because some AWS resources have a length limit and short it if needed.

We use the kubernetes style for this. For example, kubernetes -> k(# of characters)s -> k8s. And so you might see some compressions are made.

For some specific resources, we have a 32 characters limit. If the identifier length exceeds this number after compression, we remove the middle part and replace it for a hash made up from the string itself. 

## Note about tagging

There's the option to add any kind of defined tag's to each grouping module. Will be added to the commons tagging.
An example of how to set them: `{"key1": "value1", "key2": "value2"}`'

## Note about IAM Instnce profile
[The AWS IAM instance profile](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use_switch-role-ec2_instance-profiles.html) to use for the EC2 instance. Use if you want to pass an AWS role with specific permissions granted to the instance 

## Note about AWS EC2 AMI image selection

As it is defined right now, we expect a Debian based packet manager, so we require Debian based images that suports apt repos. 
This action is tested with Ubuntu 22 server image. (As the default.) We cannot ensure it will work on different specific distributions. 
If this is a requirement for you, feel free to open an issue and/or a pull request. 

### S3 buckets naming

Buckets names can be made of up to 63 characters. If the length allows us to add -tf-state, we will do so. If not, a simple -tf will be added.

## CERTIFICATES - Only for AWS Managed domains with Route53

As a default, the application will be deployed and the ELB public URL will be displayed.

If `aws_r53_domain_name` is defined, we will look up for a certificate with the name of that domain (eg. `example.com`). We expect that certificate to contain both `example.com` and `*.example.com`. 

Setting `aws_r53_create_root_cert` to `true` will create this certificate with both `example.com` and `*.example.com` for you, and validate them. (DNS validation).

Setting `aws_r53_create_sub_cert` to `true` will create a certificate **just for the subdomain**, and validate it.

> :warning: Be very careful here! **Created certificates are fully managed by Terraform**. Therefor **they will be destroyed upon stack destruction**.

To change a certificate (root_cert, sub_cert, ARN or pre-existing root cert), you must first set the `aws_r53_enable_cert` flag to false, run the action, then set the `aws_r53_enable_cert` flag to true, add the desired settings and excecute the action again. (**This will destroy the first certificate.**)

This is necessary due to a limitation that prevents certificates from being changed while in use by certain resources.

## Adding external datastore (AWS EFS)
Users looking to add non-ephemeral storage to their created EC2 instance have the following options; create a new efs as a part of the ec2 deployment stack, or mounting an existing EFS. 

### 1. Create EFS

Option 1, you have access to the `aws_efs_create` or `aws_efs_create_ha` attribute which will create a EFS resource and mount it to the EC2 instance in the application directory at the path: "app_root/data".

> :warning: Be very careful here! The **EFS is fully managed by Terraform**. Therefor **it will be destroyed upon stack destruction**.

### 2. Mount EFS
Option 2, you have access to the `mount_efs` attributes. Requiring an existing EFS id and optionally a primary security group id the existing EFS will be attached to the ec2 security group to allow traffic.

### EFS Zone Mapping
An example EFS Zone mapping;
```
{
  "a": {
    "subnet_id": "subnet-foo123",
    "security_groups: ["sg-foo123", "sg-bar456"]
  }
}
```

## Adding external database (AWS RDS or Aurora)

If `aws_rds_db_enable` and/or `aws_aurora_enable` are set to `true`, this action will deploy a RDS instance and/or Aurora cluster using Postgres as a default. 

For RDS see [this Terraform provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_instance)
For Aurora see [this Terraform provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/rds_cluster) and [this other AWS doc](https://awscli.amazonaws.com/v2/documentation/api/latest/reference/rds/create-db-parameter-group.html) to set up most of the variables.

### Environment variables
The following environment variables are added to the `.env` file in your app's `docker-compose.yaml` file.

To take advantage of these environment variables, be sure your docker-compose file is referencing the `.env` file like this:
```
version: '3.9'
services:
  app:
    # ...
    env_file: .env
    # ...
```
The RDS available environment variables are:
| Variable | Description |
|----------|-------------|
| `DB_ENGINE`| Database enginge name |
| `DB_ENGINE_VERSION`| Database engine version |
| `DB_USER`| DB Username |
| `DB_PASSWORD`| DB Password |
| `DB_NAME`| Main database name |
| `DB_PORT`| DB Port |
| `DB_HOST`| DB Host |

The Aurora available environment variables are:
| Variable | Description |
|----------|-------------|
| `AURORA_CLUSTER_ENGINE` (and `DBA_ENGINE`) | Engine name - ( mysql/postgres ) |
| `AURORA_CLUSTER_ENDPOINT` (and `DBA_HOST`) | Writer endpoint for the cluster |
| `AURORA_CLUSTER_PORT` (and `DBA_PORT`) | The database port |
| `AURORA_CLUSTER_MASTER_PASSWORD` (and `DBA_PASSWORD`) | database root password |
| `AURORA_CLUSTER_MASTER_USERNAME` (and `DBA_USER`) | The database master username |
| `AURORA_CLUSTER_DATABASE_NAME` (and `DBA_NAME`) | Name for an automatically created database on cluster creation |
| `AURORA_CLUSTER_ARN` | Amazon Resource Name (ARN) of cluster |
| `AURORA_CLUSTER_ID` | The RDS Cluster Identifier |
| `AURORA_CLUSTER_RESOURCE_ID` | The RDS Cluster Resource ID |
| `AURORA_CLUSTER_READER_ENDPOINT` | A read-only endpoint for the cluster, automatically load-balanced across replicas |
| `AURORA_CLUSTER_ENGINE_VERSION_ACTUAL` | The running version of the cluster database |
| `AURORA_CLUSTER_HOSTED_ZONE_ID`| The Route53 Hosted Zone ID of the endpoint |

### Stored secret in AWS Secrets Manager
In order to be flexible, the following variables will be used to store DB related info in AWS Secretes Manager

`username`
`password`
`host`
`port`
`database`
`engine`
`engine_version`
`DB_USER`
`DB_USERNAME`
`DB_PASSWORD`
`DB_HOST`
`DB_PORT`
`DB_NAME`
`DB_ENGINE`
`DB_ENGINE_VERSION`

### AWS Root Certs
The AWS root certificate is downloaded and accessible via the `rds-combined-ca-bundle.pem` file in root of your app repo/directory.
The new global [db certificate bundle](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/UsingWithRDS.SSL.html) is downloaded and accessible via the `aws-global-bundle.pem` file in root of your app repo/directory.

### App example
Example JavaScript to make a request to the Postgres cluster:

```js
const { Client } = require('pg')

// set up client
const client = new Client({
  host: process.env.DBA_HOST,
  port: process.env.DBA_PORT,
  user: process.env.DBA_USER,
  password: process.env.DBA_PASSWORD,
  database: process.env.DBA_NAME,
  ssl: {
    ca: fs.readFileSync('rds-combined-ca-bundle.pem').toString()
  }
});

// connect and query
client.connect()
const result = await client.query('SELECT NOW()');
await client.end();

console.log(`Hello SQL timestamp: ${result.rows[0].now}`);
```

### Aurora Infrastructure and Cluster Details
Specifically, the following resources will be created:
- AWS Security Group
  - AWS Security Group Rule - Allows access to the cluster's db port: `5432`
- AWS RDS Aurora
  - Includes a single database (set by the input: `aws_aurora_database_name`. defaults to `root`)

Additional details about the cluster that's created:
- Automated backups (7 Days)
  - Backup window 2-3 UTC (GMT)
- Encrypted Storage
- Monitoring enabled
- Sends logs to AWS Cloudwatch

> _**For more details**, see [link-to-be-updated](operations/deployment/terraform/postgres.tf)_

## Made with BitOps
[BitOps](https://bitops.sh) allows you to define Infrastructure-as-Code for multiple tools in a central place.  This action uses a BitOps [Operations Repository](https://bitops.sh/operations-repo-structure/) to set up the necessary Terraform and Ansible to create infrastructure and deploy to it.

## Contributing
We would love for you to contribute to [bitovi/github-actions-deploy-docker-to-ec2](https://github.com/bitovi/github-actions-deploy-docker-to-ec2).
Would you like to see additional features?  [Create an issue](https://github.com/bitovi/github-actions-deploy-docker-to-ec2/issues/new) or a [Pull Requests](https://github.com/bitovi/github-actions-deploy-docker-to-ec2/pulls). We love discussing solutions!

## License
The scripts and documentation in this project are released under the [MIT License](https://github.com/bitovi/github-actions-deploy-docker-to-ec2/blob/main/LICENSE).