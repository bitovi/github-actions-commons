#data "aws_caller_identity" "current" {}
#data "aws_partition" "current" {}
#data "aws_iam_policy_document"  "assume_role_with_oidc" {}

#resource "aws_eks_addon" "cluster" {
#  for_each = local.enabled ? {
#    for addon in var.addons :
#    addon.addon_name => addon
#  } : {}
#
#  cluster_name                = one(aws_eks_cluster.default[*].name)
#  addon_name                  = each.key
#  addon_version               = lookup(each.value, "addon_version", null)
#  configuration_values        = lookup(each.value, "configuration_values", null)
#  resolve_conflicts_on_create = lookup(each.value, "resolve_conflicts_on_create", null)
#  resolve_conflicts_on_update = lookup(each.value, "resolve_conflicts_on_update", null)
#  service_account_role_arn    = lookup(each.value, "service_account_role_arn", null)
#
#  tags = module.label.tags
#
#  depends_on = [
#    var.addons_depends_on,
#    aws_eks_cluster.default,
#    # OIDC provider is prerequisite for some addons. See, for example,
#    # https://docs.aws.amazon.com/eks/latest/userguide/managing-vpc-cni.html
#    aws_iam_openid_connect_provider.default,
#  ]
#
#  timeouts {
#    create = each.value.create_timeout
#    update = each.value.update_timeout
#    delete = each.value.delete_timeout
#  }
#}


resource "kubernetes_config_map" "iam_nodes_config_map" {
  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }

  data = {
    mapRoles = <<ROLES
- rolearn: ${aws_iam_role.iam_role_node.arn}
  username: system:node:{{EC2PrivateDNSName}}
  groups:
    - system:bootstrappers
    - system:nodes
- rolearn: arn:aws:iam::755521597925:role/AWSReservedSSO_AdministratorAccess_402f22a297379e03
  username: cluster-admin
  groups:
    - system:masters
ROLES
    mapAccounts = 755521597925
  }
}