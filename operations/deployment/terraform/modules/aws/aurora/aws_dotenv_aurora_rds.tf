# Additional postgres configuration in postgres.tf

resource "local_file" "aurora-dotenv" {
  filename = format("%s/%s", abspath(path.root), "aurora.env")
  content  = <<-EOT

#### Aurora values
# Amazon Resource Name (ARN) of cluster
AURORA_CLUSTER_ARN=${module.rds_cluster.cluster_arn}
# The RDS Cluster Identifier
POSTGRES_CLUSTER_ID=${module.rds_cluster.cluster_id}
# The RDS Cluster Resource ID
POSTGRES_CLUSTER_RESOURCE_ID=${module.rds_cluster.cluster_resource_id}
# Writer endpoint for the cluster
POSTGRES_CLUSTER_ENDPOINT=${module.rds_cluster.cluster_endpoint}
# A read-only endpoint for the cluster, automatically load-balanced across replicas
POSTGRES_CLUSTER_READER_ENDPOINT=${module.rds_cluster.cluster_reader_endpoint}
# The running version of the cluster database
POSTGRES_CLUSTER_ENGINE_VERSION_ACTUAL=${module.rds_cluster.cluster_engine_version_actual}
# Name for an automatically created database on cluster creation
# database_name is not set on `aws_rds_cluster[0]` resource if it was not specified, so can't be used in output
POSTGRES_CLUSTER_DATABASE_NAME=${module.rds_cluster.cluster_database_name == null ? "" : module.rds_cluster.cluster_database_name}
# The database port
POSTGRES_CLUSTER_PORT="${module.rds_cluster.cluster_port}"
# TODO: use IAM (give ec2 instance(s) access to the DB via a role)
# The database master password
POSTGRES_CLUSTER_MASTER_PASSWORD=${module.rds_cluster.cluster_master_password}
# The database master username
POSTGRES_CLUSTER_MASTER_USERNAME=${module.rds_cluster.cluster_master_username}
# The Route53 Hosted Zone ID of the endpoint
POSTGRES_CLUSTER_HOSTED_ZONE_ID=${module.rds_cluster.cluster_hosted_zone_id}
# POSTGRES specific env vars
DBA_ENGINE="${module.rds_cluster.cluster_engine ??? } #TODO: FIX THIS
PG_USER="${module.rds_cluster.cluster_master_username}"
PG_PASSWORD="${module.rds_cluster.cluster_master_password}"
PGDATABASE=${module.rds_cluster.cluster_database_name == null ? "" : module.rds_cluster.cluster_database_name}
PGPORT=${module.rds_cluster.cluster_port}
PGHOST="${module.rds_cluster.cluster_endpoint}"
EOT
}


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
