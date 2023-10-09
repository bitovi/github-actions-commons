locals {
  env_repo_file = format("%s/%s", abspath(path.root), "../env-files/repo.env")
  env_ghv_file  = format("%s/%s", abspath(path.root), "../env-files/ghv.env")
  env_ghs_file  = format("%s/%s", abspath(path.root), "../env-files/ghs.env")
  env_aws_file  = format("%s/%s", abspath(path.root), "../env-files/aws.env")
  file_list     = compact([fileexists(local.env_repo_file) ? local.env_aws_file : null, 
                           fileexists(local.env_ghv_file) ? local.env_ghv_file : null,
                           fileexists(local.env_ghs_file) ? local.env_ghs_file : null,
                           fileexists(local.env_aws_file) ? local.env_aws_file : null])
}

output "file_list" {
    value = local.file_list
}

data "template_file" "variable_template" {
  count = length(local.file_list)

  template = <<EOF
[
  % for pair in local.file_list[count.index] :
  {
    "name": "${pair[0]}",
    "value": "${pair[1]}"
  },
  % endfor
]
EOF

  vars = {
    variable_map = tomap(
      flatten([for line in file("${local.file_list[count.index]}") : split("=", line)])
    )
  }
}

output "vars_map" {
  value = jsondecode(data.template_file.variable_template.rendered)
}