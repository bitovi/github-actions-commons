resource "aws_security_group_rule" "sg_port_to_port" {
    type                     = var.sg_type
    description              = var.sg_rule_description
    from_port                = var.sg_rule_from_port
    to_port                  = var.sg_rule_to_port
    protocol                 = var.sg_rule_protocol
    source_security_group_id = var.source_security_group_id
    security_group_id        = var.target_security_group_id
}

variable "sg_type" {} #-> ingress
variable "sg_rule_description" {} #-> "${var.aws_resource_identifier} - EC2 Incoming"
variable "sg_rule_from_port" {}
variable "sg_rule_to_port" {}
variable "sg_rule_protocol" {} #-> tcp
variable "source_security_group_id" {}
variable "target_security_group_id" {}