# Security groups

resource "aws_security_group" "eks_security_group_cluster" {
  name        = var.aws_eks_security_group_name_cluster != "" ? var.aws_eks_security_group_name_cluster : "SG for ${var.aws_resource_identifier} - ${var.aws_eks_environment} - EKS Cluster"
  description = "SG for ${var.aws_resource_identifier} - EKS Cluster"
  vpc_id      = var.aws_selected_vpc_id
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "${var.aws_resource_identifier}-eks-sg-cluster"
    "kubernetes.io/cluster/${var.aws_eks_cluster_name}" = "owned"
  }
}

resource "aws_security_group" "eks_security_group_node" {
  name        = var.aws_eks_security_group_name_node != "" ? var.aws_eks_security_group_name_node : "SG for ${var.aws_resource_identifier} - ${var.aws_eks_environment} - EKS Node"
  description = "SG for ${var.aws_resource_identifier} - EKS Node"
  vpc_id      = var.aws_selected_vpc_id
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "${var.aws_resource_identifier}-eks-sg-node"
    "kubernetes.io/cluster/${var.aws_eks_cluster_name}" = "owned"
  }
}
# module.eks.aws_security_group_rule.cluster["ingress_nodes_443"]:
resource "aws_security_group_rule" "cluster" {
    description              = "Node groups to cluster API"
    from_port                = 443
    protocol                 = "tcp"
    security_group_id        = aws_security_group.eks_security_group_cluster.id
    source_security_group_id = aws_security_group.eks_security_group_node.id
    to_port                  = 443
    type                     = "ingress"
}

# module.eks.aws_security_group_rule.node["egress_all"]:
#resource "aws_security_group_rule" "node1" {
#    cidr_blocks            = [
#        "0.0.0.0/0",
#    ]
#    description            = "Allow all egress"
#    from_port              = 0
#    protocol               = "-1"
#    security_group_id      = aws_security_group.eks_security_group_node.id
#    to_port                = 0
#    type                   = "egress"
#}

# module.eks.aws_security_group_rule.node["ingress_cluster_443"]:
resource "aws_security_group_rule" "node2" {
    description              = "Cluster API to node groups"
    from_port                = 443
    protocol                 = "tcp"
    security_group_id        = aws_security_group.eks_security_group_node.id
    source_security_group_id = aws_security_group.eks_security_group_cluster.id
    to_port                  = 443
    type                     = "ingress"
}

# module.eks.aws_security_group_rule.node["ingress_cluster_4443_webhook"]:
resource "aws_security_group_rule" "node3" {
    description              = "Cluster API to node 4443/tcp webhook"
    from_port                = 4443
    protocol                 = "tcp"
    security_group_id        = aws_security_group.eks_security_group_node.id
    source_security_group_id = aws_security_group.eks_security_group_cluster.id
    to_port                  = 4443
    type                     = "ingress"
}

# module.eks.aws_security_group_rule.node["ingress_cluster_6443_webhook"]:
resource "aws_security_group_rule" "node4" {
    description              = "Cluster API to node 6443/tcp webhook"
    from_port                = 6443
    protocol                 = "tcp"
    security_group_id        = aws_security_group.eks_security_group_node.id
    source_security_group_id = aws_security_group.eks_security_group_cluster.id
    to_port                  = 6443
    type                     = "ingress"
}

# module.eks.aws_security_group_rule.node["ingress_cluster_8443_webhook"]:
resource "aws_security_group_rule" "node5" {
    description              = "Cluster API to node 8443/tcp webhook"
    from_port                = 8443
    protocol                 = "tcp"
    security_group_id        = aws_security_group.eks_security_group_node.id
    source_security_group_id = aws_security_group.eks_security_group_cluster.id
    to_port                  = 8443
    type                     = "ingress"
}

# module.eks.aws_security_group_rule.node["ingress_cluster_9443_webhook"]:
resource "aws_security_group_rule" "node6" {
    description              = "Cluster API to node 9443/tcp webhook"
    from_port                = 9443
    protocol                 = "tcp"
    security_group_id        = aws_security_group.eks_security_group_node.id
    source_security_group_id = aws_security_group.eks_security_group_cluster.id
    to_port                  = 9443
    type                     = "ingress"
}

# module.eks.aws_security_group_rule.node["ingress_cluster_kubelet"]:
resource "aws_security_group_rule" "node7" {
    description              = "Cluster API to node kubelets"
    from_port                = 10250
    protocol                 = "tcp"
    security_group_id        = aws_security_group.eks_security_group_node.id
    source_security_group_id = aws_security_group.eks_security_group_cluster.id
    to_port                  = 10250
    type                     = "ingress"
}

# module.eks.aws_security_group_rule.node["ingress_nodes_ephemeral"]:
resource "aws_security_group_rule" "node8" {
    description            = "Node to node ingress on ephemeral ports"
    from_port              = 1025
    protocol               = "tcp"
    security_group_id      = aws_security_group.eks_security_group_node.id
    self                   = true
    to_port                = 65535
    type                   = "ingress"
}

# module.eks.aws_security_group_rule.node["ingress_self_coredns_tcp"]:
resource "aws_security_group_rule" "node9" {
    description            = "Node to node CoreDNS"
    from_port              = 53
    protocol               = "tcp"
    security_group_id      = aws_security_group.eks_security_group_node.id
    self                   = true
    to_port                = 53
    type                   = "ingress"
}

# module.eks.aws_security_group_rule.node["ingress_self_coredns_udp"]:
resource "aws_security_group_rule" "node10" {
    description            = "Node to node CoreDNS UDP"
    from_port              = 53
    protocol               = "udp"
    security_group_id      = aws_security_group.eks_security_group_node.id
    self                   = true
    to_port                = 53
    type                   = "ingress"
}




## Rules 
#resource "aws_security_group_rule" "cluster" {
#    description              = "Node groups to cluster API"
#    type                     = "ingress"
#    from_port                = 443
#    to_port                  = 443
#    protocol                 = "tcp"
#    source_security_group_id = aws_security_group.eks_security_group_node.id
#    security_group_id        = aws_security_group.eks_security_group_cluster.id
#}
#
#resource "aws_security_group_rule" "rule2" {
#  description              = "Allow self communication with in cluster"
#  type                     = "ingress"
#  from_port                = "0"
#  to_port                  = "0"
#  protocol                 = "-1"
#  source_security_group_id = aws_security_group.eks_security_group_cluster.id
#  security_group_id        = aws_security_group.eks_security_group_cluster.id
#}
#
#resource "aws_security_group_rule" "rule3" {
#  description              = "Allow node to communication with each other and self"
#  type                     = "ingress"
#  from_port                = "0"
#  to_port                  = "65535"
#  protocol                 = "-1"
#  source_security_group_id = aws_security_group.eks_security_group_node.id
#  security_group_id        = aws_security_group.eks_security_group_node.id
#}
#
#resource "aws_security_group_rule" "rule4" {
#  description              = "Allow node Kubelets and pods to receive communication from the cluster control plane"
#  type                     = "ingress"
#  from_port                = "1025"
#  to_port                  = "65535"
#  protocol                 = "tcp"
#  source_security_group_id = aws_security_group.eks_security_group_cluster.id
#  security_group_id        = aws_security_group.eks_security_group_node.id
#}
#
#resource "aws_security_group_rule" "rule5" {
#  description              = "Node to node CoreDNS"
#  type                     = "ingress"
#  from_port                = 53
#  to_port                  = 53
#  protocol                 = "tcp"
#  source_security_group_id = aws_security_group.eks_security_group_cluster.id
#  security_group_id        = aws_security_group.eks_security_group_node.id
#}
#
#resource "aws_security_group_rule" "rule6" {
#  description              = "Node to node CoreDNS"
#  type                     = "ingress"
#  from_port                = 53
#  to_port                  = 53
#  protocol                 = "udp"
#  source_security_group_id = aws_security_group.eks_security_group_cluster.id
#  security_group_id        = aws_security_group.eks_security_group_node.id
#}
#
#resource "aws_security_group_rule" "rule7" {
#    count             = length(local.aws_eks_management_cidr)
#    description       = "Allow workstation or EC2 to communicate with the cluster API Server"
#    type              = "ingress"
#    from_port         = "443"
#    to_port           = "443"
#    protocol          = "tcp"
#    cidr_blocks       = element(local.aws_eks_management_cidr, count.index)
#    security_group_id = aws_security_group.eks_security_group_cluster.id
#}
#
#resource "aws_security_group_rule" "ingress_rule" {
#  count             = length(local.aws_eks_allowed_ports)   
#  description       = "Allow incoming traffic to defined services"
#  type              = "ingress"
#  from_port         = element(local.aws_eks_allowed_ports, count.index)
#  to_port           = element(local.aws_eks_allowed_ports, count.index)
#  protocol          = "tcp"
#  cidr_blocks       = [try(element(local.aws_eks_allowed_ports_cidr, count.index),"0.0.0.0/0")]  # Allow traffic from any source IP
#  security_group_id = aws_security_group.eks_security_group_node.id  # Use the appropriate security group ID
#}
#
locals {
  aws_eks_management_cidr   = var.aws_eks_management_cidr   != "" ? [for n in split(",", var.aws_eks_management_cidr)   : (n)] : []
  aws_eks_allowed_ports      = var.aws_eks_allowed_ports      != "" ? [for n in split(",", var.aws_eks_allowed_ports)      : (n)] : []
  aws_eks_allowed_ports_cidr = var.aws_eks_allowed_ports_cidr != "" ? [for n in split(",", var.aws_eks_allowed_ports_cidr) : (n)] : []
}