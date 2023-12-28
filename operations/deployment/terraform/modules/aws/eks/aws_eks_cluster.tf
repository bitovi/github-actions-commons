locals {
  aws_eks_cluster_log_types = var.aws_eks_cluster_log_types != "" ? [for n in split(",", var.aws_eks_cluster_log_types) : (n)] : []
}

resource "aws_cloudwatch_log_group" "eks" {
  count             =  var.aws_eks_cluster_log_types != "" ? 1 : 0
  name              = "/aws/eks/${var.aws_eks_cluster_name}/cluster"
  retention_in_days = tonumber(var.aws_eks_cluster_log_retention_days)
  skip_destroy      = false #var.aws_eks_cluster_logs_skip_destroy
}

resource "aws_eks_cluster" "main" {
  name     = var.aws_eks_cluster_name # Cluster name is defined during the code-generation phase
  version  = var.aws_eks_cluster_version
  role_arn = aws_iam_role.iam_role_cluster.arn
  vpc_config {
    security_group_ids      = [aws_security_group.eks_security_group_cluster.id]
    subnet_ids              = data.aws_subnets.public.ids
    endpoint_private_access = true
    endpoint_public_access  = true
  }

  enabled_cluster_log_types = local.aws_eks_cluster_log_types

  tags = {
    "kubernetes.io/cluster/${var.aws_eks_cluster_name}" = "owned"
  }
  depends_on = [ aws_cloudwatch_log_group.eks ]
}

data "aws_subnets" "private" {
  filter {
    name    = "vpc-id"
    values = [var.aws_selected_vpc_id]
  }
  tags = {
    Tier = "Private"
  }
}

data "aws_subnets" "public" {
  filter {
    name   = "vpc-id"
    values = [var.aws_selected_vpc_id]
  }
  tags = {
    Tier = "Public"
  }
}

data "aws_eks_cluster" "eks_cluster" {
  name = aws_eks_cluster.main.id
}

data "aws_eks_cluster_auth" "cluster_auth" {
  name = aws_eks_cluster.main.id
}

resource "aws_eks_node_group" "node_nodes" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${var.aws_resource_identifier}-ng"
  node_role_arn   = aws_iam_role.iam_role_node.arn
  subnet_ids      = data.aws_subnets.private.ids

  scaling_config {
    desired_size = var.aws_eks_desired_capacity
    max_size     = var.aws_eks_max_size
    min_size     = var.aws_eks_min_size
  }

  update_config {
    max_unavailable = 1
  }

  ami_type = "AL2_x86_64"
  instance_types = [var.aws_eks_instance_type]

  remote_access {
    ec2_ssh_key = var.aws_eks_ec2_key_pair != "" ? var.aws_eks_ec2_key_pair : aws_key_pair.aws_key[0].id
  }

  depends_on = [
    aws_iam_role.iam_role_node,
    aws_iam_role.iam_role_cluster,
    aws_eks_cluster.main,
    aws_security_group.eks_security_group_cluster,
    aws_security_group.eks_security_group_node
  ]
  tags                   = {
    "Name" = "${aws_eks_cluster.main.name}-node"
  }
  tags_all               = {
    "Name" = "${aws_eks_cluster.main.name}-node"
  }
}

data "aws_caller_identity" "current" {}

locals {
  aws_eks_cluster_admin_role_arn = var.aws_eks_cluster_admin_role_arn != "" ? [for n in split(",", var.aws_eks_cluster_admin_role_arn) : (n)] : []
  map_worker_roles = [
    {
      rolearn  = aws_iam_role.iam_role_node.arn
      username = "system:node:{{EC2PrivateDNSName}}"
      groups   = [
        "system:bootstrappers",
        "system:nodes"
      ]
    }
  ]
  cluster_admin_roles = [
    for role_arn in local.aws_eks_cluster_admin_role_arn : {
      rolearn  = role_arn
      username = "cluster-admin"
      groups   = [
        "system:masters"
      ]
    }
  ]
}

#resource "kubernetes_config_map" "iam_nodes_config_map" {
#  metadata {
#    name      = "aws-auth"
#    namespace = "kube-system"
#  }
#
#  data = {
#    mapRoles = <<ROLES
#- rolearn: ${aws_iam_role.iam_role_node.arn}
#  username: system:node:{{EC2PrivateDNSName}}
#  groups:
#    - system:bootstrappers
#    - system:nodes
#- rolearn: ${var.aws_eks_cluster_admin_role_arn}
#  username: cluster-admin
#  groups:
#    - system:masters
#ROLES
#    mapAccounts = "${data.aws_caller_identity.current.account_id}"
#  }
#}

resource "kubernetes_config_map" "aws_auth" {
  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }

  data = {
    mapRoles    = yamlencode(distinct(concat(local.map_worker_roles, local.cluster_admin_roles)))
    #mapUsers    = replace(yamlencode(var.map_additional_iam_users), "\"", local.yaml_quote)
    mapAccounts = "${data.aws_caller_identity.current.account_id}"
  }
}

output "eks_kubernetes_provider_config" {
  value = {
    host                   = data.aws_eks_cluster.eks_cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks_cluster.certificate_authority.0.data)
    token                  = data.aws_eks_cluster_auth.cluster_auth.token
  }
}

output "aws_eks_cluster_name" {
  value = aws_eks_cluster.main.name
}

output "aws_eks_cluster_role_arn" {
  value = aws_eks_cluster.main.role_arn
}

output "private_subnets" {
  value = data.aws_subnets.private.ids
}

output "eks_host" {
  value = data.aws_eks_cluster.eks_cluster.endpoint
}