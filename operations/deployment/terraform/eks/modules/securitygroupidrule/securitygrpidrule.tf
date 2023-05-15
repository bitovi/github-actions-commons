resource "aws_security_group_rule" "sgidrule" {
  description              = var.sg_description
  type                     = var.type
  from_port                = var.from_port
  to_port                  = var.to_port
  protocol                 = var.protocol
  source_security_group_id = var.source_sg_id
  security_group_id        = var.sg_id
}
