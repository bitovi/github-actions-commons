# This file will create a key=value file with an AWS Secret stored in AWS Secret Manager
# With a JSON style of "{"key1":"value1","key2":"value2"}"

locals {
  secret_provided = (var.aws_secret_env != null ? true : false)
}

locals {
  s3_secret_raw    = local.secret_provided ? nonsensitive(jsondecode(data.aws_secretsmanager_secret_version.env_secret[0].secret_string)) : {}
  s3_secret_string = local.secret_provided ? join("\n", [for k, v in local.s3_secret_raw : "${k}=\"${v}\""]) : ""
}

data "aws_secretsmanager_secret_version" "env_secret" {
  count     = local.secret_provided ? 1 : 0
  secret_id = var.aws_secret_env
}

resource "local_file" "tf-secretdotenv" {
  count    = local.secret_provided ? 1 : 0
  filename = format("%s/%s", abspath(path.root), "aws.env")
  content  = local.secret_provided ? "${local.s3_secret_string}\n" : ""
}

