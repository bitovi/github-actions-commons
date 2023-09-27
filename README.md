# Bitovi Github Actions Commons

This is a work in progress to embed a root tool to deploy wrapper actions in order to trim the excess of inputs yet be flexible. 

## Getting Started Intro Video
No video for now. Sorry. :disappointed:

## Need help or have questions?
This project is supported by [Bitovi, a DevOps Consultancy](https://www.bitovi.com/devops-consulting) and a proud supporter of Open Source software.

You can **get help or ask questions** on [Discord channel](https://discord.gg/J7ejFsZnJ4)! Come hangout with us!

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
1. [EC2 Cloudwatch](#ec2-cloudwatch-inputs)
1. [VPC](#vpc-inputs)
1. [Certificates](#certificate-inputs)
1. [Load Balancer](#load-balancer-inputs)
1. [EFS](#efs-inputs)
1. [RDS](#rds-inputs)
1. [Amazon Aurora Inputs](#aurora-inputs)
1. [Docker](#docker-inputs)
1. [ECR](#ecr-inputs)
1. [EKS](#eks-inputs)

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
| `ansible_ssh_to_private_ip` | Boolean | Make Ansible connect to the private IP of the instance. Only usefull if using a hosted runner in the same network.'  Default is `false`. | 
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
| `aws_resource_identifier` | String | Set to override the AWS resource identifier for the deployment. Defaults to `${GITHUB_ORG_NAME}-${GITHUB_REPO_NAME}-${GITHUB_BRANCH_NAME}`. Use with destroy to destroy specific resources. |
| `aws_additional_tags` | JSON | Add additional tags to the terraform [default tags](https://www.hashicorp.com/blog/default-tags-in-the-terraform-aws-provider), any tags put here will be added to all provisioned resources.|
<hr/>
<br/>

#### **Secrets and Environment Variables Inputs**
| Name             | Type    | Description - Check note about [**environment variables**](#environment-variables). |
|------------------|---------|------------------------------------|
| `env_aws_secret` | String | Secret name to pull environment variables from AWS Secret Manager. |
| `env_repo` | String | `.env` file containing environment variables to be used with the app. Name defaults to `repo_env`. |
| `env_ghs` | String | `.env` file to be used with the app. This is the name of the [Github secret](https://docs.github.com/es/actions/security-guides/encrypted-secrets). |
| `env_ghv` | String | `.env` file to be used with the app. This is the name of the [Github variables](https://docs.github.com/en/actions/learn-github-actions/variables). |
<hr/>
<br/>

#### **EC2 Inputs**
| Name             | Type    | Description                        |
|------------------|---------|------------------------------------|
| `aws_ec2_instance_create` | Boolean | Set to `true` if you wish to create an EC2 instance. (Default is `false`). |
| `aws_ec2_ami_filter` | String | AWS AMI Filter string. Will be used to lookup for lates image based on the string. Defaults to `ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*`.' |
| `aws_ec2_ami_owner` | String | 'Owner of AWS AMI image. This ensures the provider is the one we are looking for. Defaults to `099720109477`, Canonical (Ubuntu).' |
| `aws_ec2_ami_id` | String | AWS AMI ID. Will default to latest Ubuntu 22.04 server image (HVM). Accepts `ami-###` values. |
| `aws_ec2_ami_update` | Boolean | Set this to `true` if you want to recreate the EC2 instance if there is a newer version of the AMI. Defaults to `false`.|
| `aws_ec2_iam_instance_profile` | String | The AWS IAM instance profile to use for the EC2 instance. Default is `${GITHUB_ORG_NAME}-${GITHUB_REPO_NAME}-${GITHUB_BRANCH_NAME}`|
| `aws_ec2_instance_type` | String | The AWS IAM instance type to use. Default is `t2.small`. See [this list](https://aws.amazon.com/ec2/instance-types/) for reference. |
| `aws_ec2_instance_root_vol_size` | Integer | Define the volume size (in GiB) for the root volume on the AWS Instance. Defaults to `8`. | 
| `aws_ec2_instance_root_vol_preserve` | Boolean | Set this to true to avoid deletion of root volume on termination. Defaults to `false`. | 
| `aws_ec2_security_group_name` | String | The name of the EC2 security group. Defaults to `SG for ${aws_resource_identifier} - EC2`. |
| `aws_ec2_create_keypair_sm` | Boolean | Generates and manage a secret manager entry that contains the public and private keys created for the ec2 instance. |
| `aws_ec2_instance_public_ip` | Boolean | Add a public IP to the instance or not. (Not an Elastic IP). |
| `aws_ec2_port_list` | String | Comma separated list of ports to be enabled in the EC2 instance security group. (NOT THE ELB) In a `xx,yy` format. |
| `aws_ec2_user_data_file` | String | Relative path in the repo for a user provided script to be executed with Terraform EC2 Instance creation. See [this note](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/user-data.html#user-data-shell-scripts) |
| `aws_ec2_user_data_replace_on_change`| Boolean | If `aws_ec2_user_data_file` file changes, instance will stop and start. Hence public IP will change. This will destroy and recreate the instance. Defaults to `true`. |
| `aws_ec2_additional_tags` | JSON | Add additional tags to the terraform [default tags](https://www.hashicorp.com/blog/default-tags-in-the-terraform-aws-provider), any tags put here will be added to ec2 provisioned resources.|
<hr/>
<br/>

#### **EC2 Cloudwatch Inputs**
| Name             | Type    | Description                        |
|------------------|---------|------------------------------------|
| `aws_ec2_cloudwatch_enable` | Boolean | Toggle cloudwatch creation for EC2 Instance. As default, will monitor docker logs. Create a cloudwatch.json with your config if you need to override it. Defaults to `false`.|
| `aws_ec2_cloudwatch_lg_name` | String| Log group name. Will default to `${aws_resource_identifier}-ec2-logs` if none. |
| `aws_ec2_cloudwatch_skip_destroy` | Boolean | Toggle deletion or not when destroying the stack. Defaults to `true`. |
| `aws_ec2_cloudwatch_retention_days` | String | Number of days to retain logs. 0 to never expire. Defaults to `14`. See [note](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group#retention_in_days). |
<hr/>
<br/>

#### **VPC Inputs**
| Name             | Type    | Description                        |
|------------------|---------|------------------------------------|
| `aws_vpc_create` | Boolean | Define if a VPC should be created |
| `aws_vpc_name` | String | Define a name for the VPC. Defaults to `VPC for ${aws_resource_identifier}`. |
| `aws_vpc_cidr_block` | String | Define Base CIDR block which is divided into subnet CIDR blocks. Defaults to `10.0.0.0/16`. |
| `aws_vpc_public_subnets` | String | Comma separated list of public subnets. Defaults to `10.10.110.0/24`|
| `aws_vpc_private_subnets` | String | Comma separated list of private subnets. If no input, no private subnet will be created. Defaults to `<none>`. |
| `aws_vpc_availability_zones` | String | Comma separated list of availability zones. Defaults to `aws_default_region+<random>` value. If a list is defined, the first zone will be the one used for the EC2 instance. |
| `aws_vpc_id` | String | AWS VPC ID. Accepts `vpc-###` values. |
| `aws_vpc_subnet_id` | String | AWS VPC Subnet ID. If none provided, will pick one. (Ideal when there's only one) |
| `aws_vpc_additional_tags` | JSON | Add additional tags to the terraform [default tags](https://www.hashicorp.com/blog/default-tags-in-the-terraform-aws-provider), any tags put here will be added to vpc provisioned resources.|
<hr/>
<br/>

#### **Certificate Inputs**
| Name             | Type    | Description                        |
|------------------|---------|------------------------------------|
| `aws_r53_enable` | Boolean | Set this to true if you wish to manage certificates through AWS Certificate Manager with Terraform. **See note**. Default is `false`. |
| `aws_r53_domain_name` | String | Define the root domain name for the application. e.g. bitovi.com'. |
| `aws_r53_sub_domain_name` | String | Define the sub-domain part of the URL. Defaults to `${GITHUB_ORG_NAME}-${GITHUB_REPO_NAME}-${GITHUB_BRANCH_NAME}`. |
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
| `aws_elb_create` | Boolean | Set this to true to create a load balancer and map ports to the EC2 instance.'|
| `aws_elb_security_group_name` | String | The name of the ELB security group. Defaults to `SG for ${aws_resource_identifier} - ELB`. |
| `aws_elb_app_port` | String | Port in the EC2 instance to be redirected to. Default is `3000` | 
| `aws_elb_app_protocol` | String | Protocol to enable. Could be HTTP, HTTPS, TCP or SSL. Defaults to TCP. |
| `aws_elb_listen_port` | String | Load balancer listening port. Default is `80` if NO FQDN provided, `443` if FQDN provided. |
| `aws_elb_listen_protocol` | String | Protocol to enable. Could be HTTP, HTTPS, TCP or SSL. Defaults to `TCP` if NO FQDN provided, `SSL` if FQDN provided. |
| `aws_elb_healthcheck` | String | Load balancer health check string. Default is `TCP:22`. |
| `aws_elb_additional_tags` | JSON | Add additional tags to the terraform [default tags](https://www.hashicorp.com/blog/default-tags-in-the-terraform-aws-provider), any tags put here will be added to elb provisioned resources.|
<hr/>
<br/>

#### **EFS Inputs**
| Name             | Type    | Description                        |
|------------------|---------|------------------------------------|
| `aws_efs_create` | Boolean | Toggle to indicate whether to create and EFS and mount it to the ec2 as a part of the provisioning. Note: The EFS will be managed by the stack and will be destroyed along with the stack |
| `aws_efs_create_ha` | Boolean | Toggle to indicate whether the EFS resource should be highly available (target mounts in all available zones within region) |
| `aws_efs_fs_id` | String | ID of existing EFS. |
| `aws_efs_vpc_id` | String | ID of the VPC for the EFS mount target. If aws_efs_create_ha is set to true, will create one mount target per subnet available in the VPC. If not, will create one in an automated selected region. |
| `aws_efs_subnet_ids` | String | ID (or ID's) of the subnet for the EFS mount target. (Comma separated string.) |
| `aws_efs_security_group_name` | String | The name of the EFS security group. Defaults to `SG for ${aws_resource_identifier} - EFS`. |
| `aws_efs_create_replica` | Boolean | Toggle to indiciate whether a read-only replica should be created for the EFS primary file system |
| `aws_efs_replication_destination` | String | AWS Region to target for replication. |
| `aws_efs_enable_backup_policy` | Boolean | Toggle to indiciate whether the EFS should have a backup policy |
| `aws_efs_transition_to_inactive` | String | Indicates how long it takes to transition files to the IA storage class. |
| `aws_efs_mount_target` | String | Directory path in efs to mount directory to. Default is `/`. |
| `aws_efs_ec2_mount_point` | String | The aws_efs_ec2_mount_point input represents the folder path within the EC2 instance to the data directory. Default is `/user/ubuntu/<application_repo>/data`. Additionally this value is loaded into the docker-compose `.env` file as `HOST_DIR`. |
| `aws_efs_additional_tags` | JSON | Add additional tags to the terraform [default tags](https://www.hashicorp.com/blog/default-tags-in-the-terraform-aws-provider), any tags put here will be added to efs provisioned resources.|
<hr/>
<br/>

#### **RDS Inputs**
| Name             | Type    | Description                        |
|------------------|---------|------------------------------------|
| `aws_rds_db_enable`| Boolean | Set to `true` to enable an RDS DB|
| `aws_rds_db_name`| String | The name of the database to create when the DB instance is created. If this parameter is not specified, no database is created in the DB instance. |
| `aws_rds_db_engine`| String | Which Database engine to use. Defaults to `postgres`. |
| `aws_rds_db_engine_version`| String | Which Database engine version to use. |
| `aws_rds_db_security_group_name`| String | The name of the database security group. Defaults to `SG for ${aws_resource_identifier} - RDS`. |
| `aws_rds_db_port`| String | Port where the DB listens to. |
| `aws_rds_db_subnets`| String | Specify which subnets to use as a list of strings.  Example: `i-1234,i-5678,i-9101`. |
| `aws_rds_db_allocated_storage`| String | Storage size. Defaults to `10`. |
| `aws_rds_db_max_allocated_storage`| String | Max storage size. Defaults to `0` to disable auto-scaling. |
| `aws_rds_db_instance_class`| String | DB instance server type. Defaults to `db.t3.micro`. |
| `aws_rds_db_user`| String | Username for the db. Defaults to `dbuser`. |
| `aws_rds_cloudwatch_logs_exports`| String | Set of log types to enable for exporting to CloudWatch logs. Defaults to `postgresql`. MySQL and MariaDB: `audit, error, general, slowquery`. PostgreSQL: `postgresql, upgrade`. MSSQL: `agent , error`. Oracle: `alert, audit, listener, trace`. |
| `aws_rds_additional_tags` | JSON | Add additional tags to the terraform [default tags](https://www.hashicorp.com/blog/default-tags-in-the-terraform-aws-provider), any tags put here will be added to efs provisioned resources.|
<hr/>
<br/>

#### **Aurora Inputs**
| Name             | Type    | Description                        |
|------------------|---------|------------------------------------|
| `aws_aurora_enable` | Boolean | Set to `true` to enable an [Aurora database](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/CHAP_AuroraOverview.html). (Postgres or MySQL). |
| `aws_aurora_engine` | String |  Which Database engine to use. Default is `aurora-postgresql`.|
| `aws_aurora_engine_version` | String |  Specify database version.  More information [Postgres](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/AuroraPostgreSQL.Updates.20180305.html) or [MySQL](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraMySQLReleaseNotes/Welcome.html). Default is `11.17`. (Postgres) |
| `aws_aurora_database_group_family` | String | Specify aws database group family. Default is `aurora-postgresql11`. See [this](https://awscli.amazonaws.com/v2/documentation/api/latest/reference/rds/create-db-parameter-group.html).|
| `aws_aurora_instance_class` | String | Define the size of the instances in the DB cluster. Default is `db.t3.medium`. | 
| `aws_aurora_security_group_name` | String | The name of the database security group. Defaults to `SG for ${aws_resource_identifier} - Aurora`. |
| `aws_aurora_subnets` | String | Specify which subnets to use as a list of strings.  Example: `i-1234,i-5678,i-9101`. |
| `aws_aurora_cluster_name` | String | Specify a cluster name. Will be created if it does not exist. Defaults to `aws_resource_identifier`. |
| `aws_aurora_database_name` | String | Specify a database name. Will be created if it does not exist. Defaults to `aws_resource_identifier`. |
| `aws_aurora_database_port` | String | Specify a listening port for the database. Default is `5432`.|
| `aws_aurora_restore_snapshot` | String | Restore a snapshot to the DB. Should be set only once. Changes in this value will destroy and recreate the database completely. | 
| `aws_aurora_snapshot_name` | String | Specify a database name. Will be created if it does not exist. Won't overwrite. |
| `aws_aurora_snapshot_overwrite` | Boolean | Set to true to overwrite the snapshot. |
| `aws_aurora_database_protection` | Boolean | Protects the database from deletion. Default is `false`.|
| `aws_aurora_database_final_snapshot` | Boolean | Creates a snapshot before deletion. If a string is passed, it will be used as snapsthot name. Defaults to `false`.|
| `aws_aurora_additional_tags` | JSON | Add additional tags to the terraform [default tags](https://www.hashicorp.com/blog/default-tags-in-the-terraform-aws-provider), any tags put here will be added to aurora provisioned resources.|
<hr/>
<br/>

#### **Docker Inputs**
| Name             | Type    | Description                        |
|------------------|---------|------------------------------------|
| `docker_install` | Boolean | Set to `true` to enable docker installation through Ansible. `docker-compose up` will be excecuted after. |
| `docker_remove_orphans` | Boolean | Set to `true` to turn the `--remove-orphans` flag. Defaults to `false`. |
| `docker_full_cleanup` | Boolean | Set to `true` to run `docker-compose down` and `docker system prune --all --force --volumes` after. Runs before `docker_install`. WARNING: docker volumes will be destroyed. |
| `docker_repo_app_directory` | String | Relative path for the directory of the app. (i.e. where the `docker-compose.yaml` file is located). This is the directory that is copied into the EC2 instance. Default is `/`, the root of the repository. Add a `.gha-ignore` file with a list of files to be exluded. (Using glob patterns). |
| `docker_repo_app_directory_cleanup` | Boolean | Will generate a timestamped compressed file (in the home directory of the instance) and delete the app repo directory. Runs before `docker_install` and after `docker_full_cleanup`. |
| `docker_efs_mount_target` | String | Directory path within docker env to mount directory to. Default is `/data`|
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
| `aws_ecr_lifecycle_policy_input` | String | The policy document. This is a JSON formatted string. See more details about [Policy Parameters](http://docs.aws.amazon.com/AmazonECR/latest/userguide/LifecyclePolicies.html#lifecycle_policy_parameters) in the official AWS docs' |
| `aws_ecr_public_repo_catalog` | String | Catalog data configuration for the repository. Defaults to `{}`.' |
| `aws_ecr_registry_policy_input` | String | The policy document. This is a JSON formatted string' |
| `aws_ecr_additional_tags ` | JSON | Add additional tags to the terraform [default tags](https://www.hashicorp.com/blog/default-tags-in-the-terraform-aws-provider), any tags put here will be added to aurora provisioned resources.|
<hr/>
<br/>

#### **EKS Inputs**
| Name             | Type    | Description                        |
|------------------|---------|------------------------------------|
| `aws_eks_create` | Boolean | Define if an EKS cluster should be created |
| `aws_eks_region` | String | Define the region where EKS cluster should be created. Defaults to `us-east-1`. |
| `aws_eks_security_group_name_master` | String | Define the security group name master. Defaults to `SG for ${GITHUB_ORG_NAME}-${GITHUB_REPO_NAME}-${GITHUB_BRANCH_NAME} - ${aws_eks_environment} - EKS Master`. |
| `aws_eks_security_group_name_worker` | String | Define the security group name worker. Defaults to `SG for ${GITHUB_ORG_NAME}-${GITHUB_REPO_NAME}-${GITHUB_BRANCH_NAME} - ${aws_eks_environment} - EKS Worker`. |
| `aws_eks_environment` | String | Specify the eks environment name. Defaults to `env` |
| `aws_eks_stackname` | String | Specify the eks stack name for your environment. Defaults to `eks-stack`.  |
| `aws_eks_cidr_block` | String | Define Base CIDR block which is divided into subnet CIDR blocks. Defaults to `10.0.0.0/16`. |
| `aws_eks_workstation_cidr` | String | Comma separated list of remote public CIDRs blocks to add it to Worker nodes security groups. |
| `aws_eks_availability_zones` | String | Comma separated list of availability zones. Defaults to `us-east-1a,us-east-1b`.  |
| `aws_eks_private_subnets` | String | Comma separated list of private subnets. Defaults to `10.0.1.0/24,10.0.2.0/24`. |
| `aws_eks_public_subnets` | String | Comma separated list of public subnets. Defaults to `10.0.101.0/24,10.0.102.0/24`|
| `aws_eks_cluster_name` | String | Specify the k8s cluster name. Defaults to `${GITHUB_ORG_NAME}-${GITHUB_REPO_NAME}-${GITHUB_BRANCH_NAME}-cluster` |
| `aws_eks_cluster_log_types` | String | Comma separated list of cluster log type. See [this AWS doc](https://docs.aws.amazon.com/eks/latest/userguide/control-plane-logs.html). Defaults to `none`. |
| `aws_eks_cluster_version` | String | Specify the k8s cluster version. Defaults to `1.27` |
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

## Note about resource identifiers

Most resources will contain the tag `${GITHUB_ORG_NAME}-${GITHUB_REPO_NAME}-${GITHUB_BRANCH_NAME}`, some of them, even the resource name after. 
We limit this to a 60 characters string because some AWS resources have a length limit and short it if needed.

We use the kubernetes style for this. For example, kubernetes -> k(# of characters)s -> k8s. And so you might see some compressions are made.

For some specific resources, we have a 32 characters limit. If the identifier length exceeds this number after compression, we remove the middle part and replace it for a hash made up from the string itself. 

## Note about tagging

There's the option to add any kind of defined tag's to each grouping module. Will be added to the commons tagging.
An example of how to set them: `{"key1": "value1", "key2": "value2"}`'

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

### AWS Root Certs
The AWS root certificate is downloaded and accessible via the `rds-combined-ca-bundle.pem` file in root of your app repo/directory.

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
