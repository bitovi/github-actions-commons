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


#resource "aws_security_group_rule" "ingress_ec2" {
#  count                    = var.aws_ec2_security_group != "" ? 1 : 0
#  type                     = "ingress"
#  description              = "${var.aws_resource_identifier} - EC2 Incoming"
#  from_port                = tonumber(aws_rds_cluster.aurora.port)
#  to_port                  = tonumber(aws_rds_cluster.aurora.port)
#  protocol                 = "tcp"
#  source_security_group_id = var.aws_ec2_security_group
#  security_group_id        = aws_security_group.aurora_security_group.id
#}
#
#resource "aws_security_group_rule" "ingress_ec2" {
#  count                    = var.aws_ec2_security_group != "" ? 1 : 0
#  type                     = "ingress"
#  description              = "${var.aws_resource_identifier} - EC2 Incoming"
#  from_port                = local.db_port
#  to_port                  = local.db_port
#  protocol                 = "tcp"
#  source_security_group_id = var.aws_ec2_security_group
#  security_group_id        = aws_security_group.sg_rds_proxy.id
#}
#
#resource "aws_security_group_rule" "ingress_ec2" {
#  count                    = var.aws_ec2_security_group != "" ? 1 : 0
#  type                     = "ingress"
#  description              = "${var.aws_resource_identifier} - EC2 Incoming"
#  from_port                = tonumber(aws_db_instance.default.port)
#  to_port                  = tonumber(aws_db_instance.default.port)
#  protocol                 = "tcp"
#  source_security_group_id = var.aws_ec2_security_group
#  security_group_id        = aws_security_group.rds_db_security_group.id
#}
#
#resource "aws_security_group_rule" "ingress_ec2" {
#  count                    = var.aws_ec2_security_group != "" ? 1 : 0
#  type                     = "ingress"
#  description              = "${var.aws_resource_identifier} - EC2 Incoming"
#  from_port                = tonumber(aws_elasticache_replication_group.redis_cluster.port)
#  to_port                  = tonumber(aws_elasticache_replication_group.redis_cluster.port)
#  protocol                 = "tcp"
#  source_security_group_id = var.aws_ec2_security_group
#  security_group_id        = aws_security_group.redis_security_group.id
#}

