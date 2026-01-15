# This file will create a key=value file with an AWS Secret stored in AWS Secret Manager
# With a JSON style of "{"key1":"value1","key2":"value2"}"
data "aws_secretsmanager_secret_version" "secret_list" {
  count     = length(local.env_aws_secret)
  secret_id = local.env_aws_secret[count.index]
}

resource "local_file" "tf-secretdotenv" {
  filename = format("%s/%s", abspath(path.root), "aws.env")
  content  = join("\n", local.s3_secret_string)
}

locals {
  env_aws_secret = [for n in split(",", var.env_aws_secret) : (n)]
  all_secret_contents = {
    for secret_name, secret_data in data.aws_secretsmanager_secret_version.secret_list : secret_name => jsondecode(secret_data.secret_string)
  }
  merged_secrets   = merge(values(local.all_secret_contents)...)
  s3_secret_string = [for key, value in local.merged_secrets : "${key}=${value}"]
}