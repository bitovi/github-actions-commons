resource "aws_security_group_rule" "rule" {
    description       = var.sg_description
    type              = var.type
    from_port         = var.from_port
    to_port           = var.to_port
    protocol          = var.protocol
    # cidr_blocks     = ["${split(",", var.cidr)}"]
    cidr_blocks       = var.cidr
    security_group_id = var.sg_id
}