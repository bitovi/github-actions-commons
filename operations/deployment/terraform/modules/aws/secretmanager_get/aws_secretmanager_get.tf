# This file will create a key=value file with an AWS Secret stored in AWS Secret Manager
# With a JSON style of "{"key1":"value1","key2":"value2"}"
data "aws_secretsmanager_secret_version" "env_secret" {
  secret_id = var.env_aws_secret
}

resource "local_file" "tf-secretdotenv" {
  filename = format("%s/%s", abspath(path.root), "aws.env")
  content  = "${local.s3_secret_string}\n"
}

locals {
  s3_secret_raw    = nonsensitive(jsondecode(data.aws_secretsmanager_secret_version.env_secret.secret_string))
  s3_secret_string = join("\n", [for k, v in local.s3_secret_raw : "${k}=\"${v}\""])
}