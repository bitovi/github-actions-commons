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
```

## Customizing

### Inputs
1. [GitHub Deployment repo inputs](#github-deployment-repo-inputs)
1. [GitHub Action repo inputs](#github-action-repo-inputs)
1. [Action default inputs](#action-default-inputs)
1. [AWS Specific](#aws-specific)
1. [Secrets and Environment Variables](#secrets-and-environment-variables-inputs)
1. [EC2](#ec2-inputs)
1. [Certificates](#certificate-inputs)
1. [Load Balancer](#load-balancer-inputs)
1. [EFS](#efs-inputs)
1. [RDS](#rds-inputs)
1. [Docker](#docker-inputs)

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
<hr/>
<br/>

#### **GitHub Action repo inputs**
| Name             | Type    | Description                        |
|------------------|---------|------------------------------------|
| `gh_action_repo` | String | URL of calling repo. |
| `gh_action_input_terraform` | String | Folder to store Terraform files to be included during Terraform execution. |
| `gh_action_input_ansible` | String | Folder where a whole Ansible structure is expected. If missing bitops.config.yaml a default will be generated. |
| `gh_action_input_ansible_playbook` | String | Main playbook to be looked for. Defaults to `playbook.yml`.|
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
| `tf_state_bucket` | String | AWS S3 bucket name to use for Terraform state. See [note](#s3-buckets-naming) | 
| `tf_state_bucket_destroy` | Boolean | Force purge and deletion of S3 bucket defined. Any file contained there will be destroyed. `tf_stack_destroy` must also be `true`. Default is `false`. |
| `tf_state_bucket_provider` | String | Bucket provider for Terraform State storage. [Disabled ATM, AWS as a default.] | 
| `tf_targets` | List | A list of targets to create before the full stack creation. | 
| `ansible_skip` | Boolean | Skip Ansible execution after Terraform excecution. |
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
| `aws_ec2_instance_protect` | Boolean | Set this to true to enable API instance deletion protection. Defaults to `false`. |
| `aws_ec2_instance_root_vol_size` | Integer | Define the volume size (in GiB) for the root volume on the AWS Instance. Defaults to `8`. | 
| `aws_ec2_instance_root_vol_preserve` | Boolean | Set this to true to avoid deletion of root volume on termination. Defaults to `false`. | 
| `aws_ec2_security_group_name` | String | The name of the EC2 security group. Defaults to `SG for ${aws_resource_identifier} - EC2`. |
| `aws_ec2_create_keypair_sm` | Boolean | Generates and manage a secret manager entry that contains the public and private keys created for the ec2 instance. |
| `aws_ec2_instance_public_ip` | Boolean | Add a public IP to the instance or not. (Not an Elastic IP). |
| `aws_ec2_port_list` | String | Comma separated list of ports to be enabled in the EC2 instance security group. (NOT THE ELB) In a `xx,yy` format. |
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
<hr/>
<br/>

#### **Load Balancer Inputs**
| Name             | Type    | Description                        |
|------------------|---------|------------------------------------|
| `aws_elb_app_port` | String | Port to be expose for the container. Default is `3000` | 
| `aws_elb_app_protocol` | String | Protocol to enable. Could be HTTP, HTTPS, TCP or SSL. Defaults to TCP. |
| `aws_elb_listen_port` | String | Load balancer listening port. Default is `80` if NO FQDN provided, `443` if FQDN provided. |
| `aws_elb_listen_protocol` | String | Protocol to enable. Could be HTTP, HTTPS, TCP or SSL. Defaults to TCP if NO FQDN provided, SSL if FQDN provided. |
| `aws_elb_healthcheck` | String | Load balancer health check string. Default is `HTTP:aws_elb_app_port`. |
<hr/>
<br/>

#### **EFS Inputs**
| Name             | Type    | Description                        |
|------------------|---------|------------------------------------|
| `aws_efs_create` | Boolean | Toggle to indicate whether to create and EFS and mount it to the ec2 as a part of the provisioning. Note: The EFS will be managed by the stack and will be destroyed along with the stack |
| `aws_efs_create_ha` | Boolean | Toggle to indicate whether the EFS resource should be highly available (target mounts in all available zones within region) |
| `aws_efs_create_replica` | Boolean | Toggle to indiciate whether a read-only replica should be created for the EFS primary file system |
| `aws_efs_enable_backup_policy` | Boolean | Toggle to indiciate whether the EFS should have a backup policy |
| `aws_efs_volume_preserve` | Boolean | Set this to true to avoid deletion of EFS volume on termination. Defaults to `false`.|
| `aws_efs_zone_mapping` | JSON | Zone Mapping in the form of `{\"<availabillity zone>\":{\"subnet_id\":\"subnet-abc123\", \"security_groups\":\[\"sg-abc123\"\]} }` |
| `aws_efs_transition_to_inactive` | String | Indicates how long it takes to transition files to the IA storage class. |
| `aws_efs_replication_destination` | String | AWS Region to target for replication. |
| `aws_efs_mount_id` | String | ID of existing EFS. |
| `aws_efs_mount_security_group_id` | String | ID of the primary security group used by the existing EFS. |
| `aws_efs_mount_target` | String | Directory path in efs to mount directory to. Default is `/`. |
| `aws_efs_ec2_mount_point` | String | The aws_efs_ec2_mount_point input represents the folder path within the EC2 instance to the data directory. Default is `/user/ubuntu/<application_repo>/data`. Additionally this value is loaded into the docker-compose `.env` file as `HOST_DIR`. |
<hr/>
<br/>

#### **RDS Inputs**
| Name             | Type    | Description                        |
|------------------|---------|------------------------------------|
| `aws_postgres_enable` | Boolean | Set to "true" to enable a postgres database. |
| `aws_postgres_engine` | String |  Which Database engine to use. Default is `aurora-postgresql`.|
| `aws_postgres_engine_version` | String |  Specify Postgres version.  More information [here](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/AuroraPostgreSQL.Updates.20180305.html). Default is `11.13`. |
| `aws_postgres_instance_class` | String | Define the size of the instances in the DB cluster. Default is `db.t3.medium`. | 
| `aws_postgres_security_group_name` | String | The name of the Postgres security group. Defaults to `SG for ${aws_resource_identifier} - PG`. |
| `aws_postgres_subnets` | String | Specify which subnets to use as a list of strings.  Example: `i-1234,i-5678,i-9101`. |
| `aws_postgres_database_name` | String | Specify a database name. Will be created if it does not exist. Default is `root`. |
| `aws_postgres_database_port` | String | Specify a listening port for the database. Default is `5432`.|
| `aws_postgres_database_protection` | Boolean | Protects the database from deletion. Default is `false`.|
| `aws_postgres_database_final_snapshot` | Boolean | Creates a snapshot before deletion. If a string is passed, it will be used as snapsthot name. Defaults to `false`.|
<hr/>
<br/>

#### **Docker Inputs**
| Name             | Type    | Description                        |
|------------------|---------|------------------------------------|
| `docker_install` | Boolean | Set to "true" to enable docker installation through Ansible. docker-compose up will be excecuted after. |
| `docker_repo_app_directory` | String | Relative path for the directory of the app. (i.e. where the `docker-compose.yaml` file is located). This is the directory that is copied into the EC2 instance. Default is `/`, the root of the repository. |
| `docker_efs_mount_target` | String | Directory path within docker env to mount directory to. Default is `/data`|
<hr/>
<br/>
<br/>

## Note about resource identifiers

Most resources will contain the tag `${GITHUB_ORG_NAME}-${GITHUB_REPO_NAME}-${GITHUB_BRANCH_NAME}`, some of them, even the resource name after. 
We limit this to a 60 characters string because some AWS resources have a length limit and short it if needed.

We use the kubernetes style for this. For example, kubernetes -> k(# of characters)s -> k8s. And so you might see some compressions are made.

For some specific resources, we have a 32 characters limit. If the identifier length exceeds this number after compression, we remove the middle part and replace it for a hash made up from the string itself. 

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

## Adding external Postgres database (AWS RDS)

If `aws_postgres_enable` is set to `true`, this action will deploy an RDS cluster for Postgres.

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

The available environment variables are:
| Variable | Description |
|----------|-------------|
| `POSTGRES_CLUSTER_ENDPOINT` (and `PGHOST`) | Writer endpoint for the cluster |
| `POSTGRES_CLUSTER_PORT` (and `PGPORT`) | The database port |
| `POSTGRES_CLUSTER_MASTER_PASSWORD` (and `PG_PASSWORD`) | database root password |
| `POSTGRES_CLUSTER_MASTER_USERNAME` (and `PG_USER`) | The database master username |
| `POSTGRES_CLUSTER_DATABASE_NAME` (and `PGDATABASE`) | Name for an automatically created database on cluster creation |
| `POSTGRES_CLUSTER_ARN` | Amazon Resource Name (ARN) of cluster |
| `POSTGRES_CLUSTER_ID` | The RDS Cluster Identifier |
| `POSTGRES_CLUSTER_RESOURCE_ID` | The RDS Cluster Resource ID |
| `POSTGRES_CLUSTER_READER_ENDPOINT` | A read-only endpoint for the cluster, automatically load-balanced across replicas |
| `POSTGRES_CLUSTER_ENGINE_VERSION_ACTUAL` | The running version of the cluster database |
| `POSTGRES_CLUSTER_HOSTED_ZONE_ID`| The Route53 Hosted Zone ID of the endpoint |

### AWS Root Certs
The AWS root certificate is downloaded and accessible via the `rds-combined-ca-bundle.pem` file in root of your app repo/directory.

### App example
Example JavaScript to make a request to the Postgres cluster:

```js
const { Client } = require('pg')

// set up client
const client = new Client({
  host: process.env.PGHOST,
  port: process.env.PGPORT,
  user: process.env.PG_USER,
  password: process.env.PG_PASSWORD,
  database: process.env.PGDATABASE,
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

### Postgres Infrastructure and Cluster Details
Specifically, the following resources will be created:
- AWS Security Group
  - AWS Security Group Rule - Allows access to the cluster's db port: `5432`
- AWS RDS Aurora Postgres
  - Includes a single database (set by the input: `aws_postgres_database_name`. defaults to `root`)

Additional details about the cluster that's created:
- Automated backups (7 Days)
  - Backup window 2-3 UTC (GMT)
- Encrypted Storage
- Monitoring enabled
- Sends logs to AWS Cloudwatch

> _**For more details**, see [operations/deployment/terraform/postgres.tf](operations/deployment/terraform/postgres.tf)_

## Made with BitOps
[BitOps](https://bitops.sh) allows you to define Infrastructure-as-Code for multiple tools in a central place.  This action uses a BitOps [Operations Repository](https://bitops.sh/operations-repo-structure/) to set up the necessary Terraform and Ansible to create infrastructure and deploy to it.

## Contributing
We would love for you to contribute to [bitovi/github-actions-deploy-docker-to-ec2](https://github.com/bitovi/github-actions-deploy-docker-to-ec2).
Would you like to see additional features?  [Create an issue](https://github.com/bitovi/github-actions-deploy-docker-to-ec2/issues/new) or a [Pull Requests](https://github.com/bitovi/github-actions-deploy-docker-to-ec2/pulls). We love discussing solutions!

## License
The scripts and documentation in this project are released under the [MIT License](https://github.com/bitovi/github-actions-deploy-docker-to-ec2/blob/main/LICENSE).
