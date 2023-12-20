# Security groups

resource "aws_security_group" "eks_security_group_master" {
  name        = var.aws_eks_security_group_name_master != "" ? var.aws_eks_security_group_name_master : "SG for ${var.aws_resource_identifier} - ${var.aws_eks_environment} - EKS Master"
  description = "SG for ${var.aws_resource_identifier} - EKS Master"
  vpc_id      = var.aws_selected_vpc_id
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "${var.aws_resource_identifier}-eks-sg-mstr"
    "kubernetes.io/cluster/${var.aws_eks_cluster_name}" = "owned"
  }
}

resource "aws_security_group" "eks_security_group_worker" {
  name        = var.aws_eks_security_group_name_worker != "" ? var.aws_eks_security_group_name_worker : "SG for ${var.aws_resource_identifier} - ${var.aws_eks_environment} - EKS Worker"
  description = "SG for ${var.aws_resource_identifier} - EKS Worker"
  vpc_id      = var.aws_selected_vpc_id
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "${var.aws_resource_identifier}-eks-sg-wrkr"
    "kubernetes.io/cluster/${var.aws_eks_cluster_name}" = "owned"
  }
}

# Rules 
resource "aws_security_group_rule" "rule1" {
  description              = "Allow pods to communicate with the cluster API Server"
  type                     = "ingress"
  from_port                = "443"
  to_port                  = "443"
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.eks_security_group_worker.id
  security_group_id        = aws_security_group.eks_security_group_master.id
}

resource "aws_security_group_rule" "rule2" {
  description              = "Allow self communication with in master"
  type                     = "ingress"
  from_port                = "0"
  to_port                  = "0"
  protocol                 = "-1"
  source_security_group_id = aws_security_group.eks_security_group_master.id
  security_group_id        = aws_security_group.eks_security_group_master.id
}

resource "aws_security_group_rule" "rule3" {
  description              = "Allow node to communication with each other and self"
  type                     = "ingress"
  from_port                = "0"
  to_port                  = "65535"
  protocol                 = "-1"
  source_security_group_id = aws_security_group.eks_security_group_worker.id
  security_group_id        = aws_security_group.eks_security_group_worker.id
}

resource "aws_security_group_rule" "rule4" {
  description              = "Allow worker Kubelets and pods to receive communication from the cluster control plane"
  type                     = "ingress"
  from_port                = "1025"
  to_port                  = "65535"
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.eks_security_group_master.id
  security_group_id        = aws_security_group.eks_security_group_worker.id
}

resource "aws_security_group_rule" "rule5" {
  description              = "Node to node CoreDNS"
  type                     = "ingress"
  from_port                = 53
  to_port                  = 53
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.eks_security_group_worker.id
  security_group_id        = aws_security_group.eks_security_group_master.id
}

resource "aws_security_group_rule" "rule5" {
  description              = "Node to node CoreDNS"
  type                     = "ingress"
  from_port                = 53
  to_port                  = 53
  protocol                 = "udp"
  source_security_group_id = aws_security_group.eks_security_group_worker.id
  security_group_id        = aws_security_group.eks_security_group_master.id
}

resource "aws_security_group_rule" "rule6" {
    count             = length(local.aws_eks_management_cidr)
    description       = "Allow workstation or EC2 to communicate with the cluster API Server"
    type              = "ingress"
    from_port         = "443"
    to_port           = "443"
    protocol          = "tcp"
    cidr_blocks       = element(local.aws_eks_management_cidr, count.index)
    security_group_id = aws_security_group.eks_security_group_master.id
}

resource "aws_security_group_rule" "ingress_rule" {
  count             = length(local.aws_eks_allowed_ports)   
  description       = "Allow incoming traffic to defined services"
  type              = "ingress"
  from_port         = element(local.aws_eks_allowed_ports, count.index)
  to_port           = element(local.aws_eks_allowed_ports, count.index)
  protocol          = "tcp"
  cidr_blocks       = [try(element(local.aws_eks_allowed_ports_cidr, count.index),"0.0.0.0/0")]  # Allow traffic from any source IP
  security_group_id = aws_security_group.eks_security_group_worker.id  # Use the appropriate security group ID
}

locals {
  aws_eks_management_cidr   = var.aws_eks_management_cidr   != "" ? [for n in split(",", var.aws_eks_management_cidr)   : (n)] : []
  aws_eks_allowed_ports      = var.aws_eks_allowed_ports      != "" ? [for n in split(",", var.aws_eks_allowed_ports)      : (n)] : []
  aws_eks_allowed_ports_cidr = var.aws_eks_allowed_ports_cidr != "" ? [for n in split(",", var.aws_eks_allowed_ports_cidr) : (n)] : []
}