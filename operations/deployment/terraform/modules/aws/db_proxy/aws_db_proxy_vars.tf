variable aws_db_proxy_name {}
variable aws_db_proxy_database_id {}
variable aws_db_proxy_cluster {} # -> bool
variable aws_db_proxy_secret_name {} # Secret containing DB variables
variable aws_db_proxy_client_password_auth_type {} # -> MYSQL_NATIVE_PASSWORD, POSTGRES_SCRAM_SHA_256, -POSTGRES_MD5-, and SQL_SERVER_AUTHENTICATION. 
variable aws_db_proxy_tls {}# Boolean  -> true
variable aws_db_proxy_security_group_name {} # AWS Resource id if not
variable aws_db_proxy_database_security_group_allow {} # Boolean -> True - Will add a rule to every sg asociated with the DB
variable aws_db_proxy_allowed_security_group {} # -> list of. Will use all of the defaults if not
variable aws_db_proxy_allow_all_incoming {}
variable aws_db_proxy_cloudwatch_enable {} 
variable aws_db_proxy_cloudwatch_retention_days {}
variable aws_selected_vpc_id {}
variable aws_selected_subnets {}
variable aws_resource_identifier {}
