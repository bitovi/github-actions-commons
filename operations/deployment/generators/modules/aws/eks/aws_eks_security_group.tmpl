# Security groups

resource "aws_security_group" "eks_security_group_master" {
  name        = var.aws_eks_security_group_name_master != "" ? var.aws_eks_security_group_name_master : "SG for ${var.aws_resource_identifier} - ${var.aws_eks_environment} - EKS Master"
  description = "SG for ${var.aws_resource_identifier} - EKS Master"
  vpc_id      = module.eks_vpc.vpc_id
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
  vpc_id      = module.eks_vpc.vpc_id
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
    count             = length(local.aws_eks_workstation_cidr) > 0 ? 1 : 0
    description       = "Allow workstation or EC2 to communicate with the cluster API Server"
    type              = "ingress"
    from_port         = "443"
    to_port           = "443"
    protocol          = "tcp"
    cidr_blocks       = local.aws_eks_workstation_cidr
    security_group_id = aws_security_group.eks_security_group_master.id
}

locals {
  aws_eks_workstation_cidr = var.aws_eks_workstation_cidr != "" ? [for n in split(",", var.aws_eks_workstation_cidr) : (n)] : []
}