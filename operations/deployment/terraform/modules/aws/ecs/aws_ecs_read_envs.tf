locals {
  env_repo_file = format("%s/%s", abspath(path.root), "../env-files/repo.env")
  env_ghv_file  = format("%s/%s", abspath(path.root), "../env-files/ghv.env")
  env_ghs_file  = format("%s/%s", abspath(path.root), "../env-files/ghs.env")
  env_aws_file  = format("%s/%s", abspath(path.root), "../env-files/aws.env")  
}

data "template_file" "variable_template" {
  count = can(file(local.env_repo_file)) ? 1 : 0
  template = <<EOF
[
  % for pair in local.env_repo_file :
  {
    "name": "${pair.key}",
    "value": "${pair.value}"
  },
  % endfor
]
EOF

  vars = {
    variable_map = tomap(
      flatten([for line in file("${local.env_repo_file}") : split("=", line)])
    )
  }
}

output "vars_map" {
  value = jsondecode(data.template_file.variable_template.rendered)
}