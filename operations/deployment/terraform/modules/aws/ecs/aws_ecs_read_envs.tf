locals {
  env_repo_file = format("%s/%s", abspath(path.root), "../../env-files/repo.env")
  env_ghv_file  = format("%s/%s", abspath(path.root), "../../env-files/ghv.env")
  env_ghs_file  = format("%s/%s", abspath(path.root), "../../env-files/ghs.env")
  env_aws_file  = format("%s/%s", abspath(path.root), "../../env-files/aws.env")
}

data "local_file" "env_repo_file" {
  count = fileexists(local.env_repo_file) ? 1 : 0
  filename =  local.env_repo_file
}

data "local_file" "env_ghv_file" {
  count = fileexists(local.env_ghv_file) ? 1 : 0
  filename =  local.env_ghv_file
}

data "local_file" "env_ghs_file" {
  count = fileexists(local.env_ghs_file) ? 1 : 0
  filename =  local.env_ghs_file
}

data "local_file" "env_aws_file" {
  count = fileexists(local.env_aws_file) ? 1 : 0
  filename =  local.env_aws_file
}

locals {
  repo_content = length(data.local_file.env_repo_file) == 0 ? null : data.local_file.env_repo_file[0].content
  ghv_content  = length(data.local_file.env_ghv_file)  == 0 ? null : data.local_file.env_ghv_file[0].content
  ghs_content  = length(data.local_file.env_ghs_file)  == 0 ? null : data.local_file.env_ghs_file[0].content
  aws_content  = length(data.local_file.env_aws_file)  == 0 ? null : data.local_file.env_aws_file[0].content

  merged_content = join("\n", [
    for content in [
      local.repo_content,
      local.ghv_content,
      local.ghs_content,
      local.aws_content,
    ] : content != null ? content : ""
  ])

  env_repo_vars = [
    for key, value in { for tuple in regexall("(.*?)=(.*)", local.merged_content) : tuple[0] => tuple[1] } : {
      name  = key
      value = value
    }
   ]
}

resource "null_resource" "list_directory" {
  triggers = {
    always_run = "${timestamp()}"
  }

  provisioner "local-exec" {
    command = "ls -l ${format("%s/%s", abspath(path.root), "../../env-files")}"
  }
}