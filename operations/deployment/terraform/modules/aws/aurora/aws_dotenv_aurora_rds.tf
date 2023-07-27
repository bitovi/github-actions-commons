# Additional postgres configuration in postgres.tf

resource "local_file" "aurora-dotenv" {
  filename = format("%s/%s", abspath(path.root), "aurora.env")
  content  = <<-EOT

#### Aurora values
# Amazon Resource Name (ARN) of cluster
AURORA_CLUSTER_ARN=${module.aurora_cluster.cluster_arn}
# The RDS Cluster Identifier
AURORA_CLUSTER_ID=${module.aurora_cluster.cluster_id}
# The RDS Cluster Resource ID
AURORA_CLUSTER_RESOURCE_ID=${module.aurora_cluster.cluster_resource_id}
# Writer endpoint for the cluster
AURORA_CLUSTER_ENDPOINT=${module.aurora_cluster.cluster_endpoint}
# A read-only endpoint for the cluster, automatically load-balanced across replicas
AURORA_CLUSTER_READER_ENDPOINT=${module.aurora_cluster.cluster_reader_endpoint}
# The running version of the cluster database
AURORA_CLUSTER_ENGINE_VERSION_ACTUAL=${module.aurora_cluster.cluster_engine_version_actual}
# Name for an automatically created database on cluster creation
# database_name is not set on `aws_aurora_cluster[0]` resource if it was not specified, so can't be used in output
AURORA_CLUSTER_DATABASE_NAME=${module.aurora_cluster.cluster_database_name == null ? "" : module.aurora_cluster.cluster_database_name}
# The database port
AURORA_CLUSTER_PORT="${module.aurora_cluster.cluster_port}"
# TODO: use IAM (give ec2 instance(s) access to the DB via a role)
# The database master password
AURORA_CLUSTER_MASTER_PASSWORD=${module.aurora_cluster.cluster_master_password}
# The database master username
AURORA_CLUSTER_MASTER_USERNAME=${module.aurora_cluster.cluster_master_username}
# The Route53 Hosted Zone ID of the endpoint
AURORA_CLUSTER_HOSTED_ZONE_ID=${module.aurora_cluster.cluster_hosted_zone_id}
# AURORA specific env vars
DBA_ENGINE="${var.aws_aurora_engine}
DBA_USER="${module.aurora_cluster.cluster_master_username}"
DBA_PASSWORD="${module.aurora_cluster.cluster_master_password}"
DBA_NAME=${module.aurora_cluster.cluster_database_name == null ? "" : module.aurora_cluster.cluster_database_name}
DBA_PORT=${module.aurora_cluster.cluster_port}
DBA_HOST="${module.aurora_cluster.cluster_endpoint}"
EOT
}

resource "local_file" "postgres-dotenv" {
  filename = format("%s/%s", abspath(path.root), "postgres.env")
  content  = <<-EOT

#### Aurora values
# Amazon Resource Name (ARN) of cluster
POSTGRES_CLUSTER_ARN=${module.aurora_cluster.cluster_arn}
# The RDS Cluster Identifier
POSTGRES_CLUSTER_ID=${module.aurora_cluster.cluster_id}
# The RDS Cluster Resource ID
POSTGRES_CLUSTER_RESOURCE_ID=${module.aurora_cluster.cluster_resource_id}
# Writer endpoint for the cluster
POSTGRES_CLUSTER_ENDPOINT=${module.aurora_cluster.cluster_endpoint}
# A read-only endpoint for the cluster, automatically load-balanced across replicas
POSTGRES_CLUSTER_READER_ENDPOINT=${module.aurora_cluster.cluster_reader_endpoint}
# The running version of the cluster database
POSTGRES_CLUSTER_ENGINE_VERSION_ACTUAL=${module.aurora_cluster.cluster_engine_version_actual}
# Name for an automatically created database on cluster creation
# database_name is not set on `aws_aurora_cluster[0]` resource if it was not specified, so can't be used in output
POSTGRES_CLUSTER_DATABASE_NAME=${module.aurora_cluster.cluster_database_name == null ? "" : module.aurora_cluster.cluster_database_name}
# The database port
POSTGRES_CLUSTER_PORT="${module.aurora_cluster.cluster_port}"
# TODO: use IAM (give ec2 instance(s) access to the DB via a role)
# The database master password
POSTGRES_CLUSTER_MASTER_PASSWORD=${module.aurora_cluster.cluster_master_password}
# The database master username
POSTGRES_CLUSTER_MASTER_USERNAME=${module.aurora_cluster.cluster_master_username}
# The Route53 Hosted Zone ID of the endpoint
POSTGRES_CLUSTER_HOSTED_ZONE_ID=${module.aurora_cluster.cluster_hosted_zone_id}
# POSTGRES specific env vars
DBA_ENGINE="${var.aws_aurora_engine} 
PG_USER="${module.aurora_cluster.cluster_master_username}"
PG_PASSWORD="${module.aurora_cluster.cluster_master_password}"
PGDATABASE=${module.aurora_cluster.cluster_database_name == null ? "" : module.aurora_cluster.cluster_database_name}
PGPORT=${module.aurora_cluster.cluster_port}
PGHOST="${module.aurora_cluster.cluster_endpoint}"
EOT
}