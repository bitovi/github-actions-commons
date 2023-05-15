resource "aws_security_group" "sg" {
  name        = var.securitygroup_name
  description = var.securitygroup_description
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  /*
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = var.ingress_cidr_blocks
  }
  */

  tags = {
    "kubernetes.io/cluster/${var.kubernetes_cluster_name}" = "owned"
  }
  depends_on  = [var.sg_depends_on]
}

output "sg_id" {
  value = aws_security_group.sg.id
}
