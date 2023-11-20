# Additional postgres configuration in postgres.tf

locals {
  dba_engine = var.aws_aurora_engine == "aurora-postgresql" ? "postgres" : "mysql"
}

resource "local_file" "aurora-dotenv" {
  filename = format("%s/%s", abspath(path.root), "aurora.env")
  content  = <<-EOT

#### Aurora values
# Amazon Resource Name (ARN) of cluster
AURORA_CLUSTER_ARN=${aws_rds_cluster.aurora.arn}
# The RDS Cluster Identifier
AURORA_CLUSTER_ID=${aws_rds_cluster.aurora.cluster_identifier}
# The RDS Cluster Resource ID
AURORA_CLUSTER_RESOURCE_ID=${aws_rds_cluster.aurora.cluster_resource_id}
# Writer endpoint for the cluster
AURORA_CLUSTER_ENDPOINT=${aws_rds_cluster.aurora.endpoint}
# A read-only endpoint for the cluster, automatically load-balanced across replicas
AURORA_CLUSTER_READER_ENDPOINT=${aws_rds_cluster.aurora.endpoint}
# The running version of the cluster database
AURORA_CLUSTER_ENGINE_VERSION_ACTUAL=${aws_rds_cluster.aurora.engine_version_actual}
# Name for an automatically created database on cluster creation
# database_name is not set on `aws_aurora_cluster[0]` resource if it was not specified, so can't be used in output
AURORA_CLUSTER_DATABASE_NAME=${aws_rds_cluster.aurora.database_name == null ? "" : aws_rds_cluster.aurora.database_name}
# The database port
AURORA_CLUSTER_PORT="${aws_rds_cluster.aurora.port}"
# TODO: use IAM (give ec2 instance(s) access to the DB via a role)
# The database master password
AURORA_CLUSTER_MASTER_PASSWORD=${aws_rds_cluster.aurora.master_password}
# The database master username
AURORA_CLUSTER_MASTER_USERNAME=${aws_rds_cluster.aurora.master_username}
# The Route53 Hosted Zone ID of the endpoint
AURORA_CLUSTER_HOSTED_ZONE_ID=${aws_rds_cluster.aurora.hosted}
# AURORA specific env vars
DBA_ENGINE="${local.dba_engine}
DBA_USER="${aws_rds_cluster.aurora.master_username}"
DBA_PASSWORD="${aws_rds_cluster.aurora.master_password}"
DBA_NAME=${aws_rds_cluster.aurora.database_name == null ? "" : aws_rds_cluster.aurora.dabase_name}
DBA_PORT=${aws_rds_cluster.aurora.port}
DBA_HOST="${aws_rds_cluster.aurora.endpoint}"
EOT
}