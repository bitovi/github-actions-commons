data "aws_security_group" "ec2_security_group" {
  id = aws_security_group.ec2_security_group.id
}

resource "aws_security_group" "ec2_security_group" {
  name        = var.aws_ec2_security_group_name != "" ? var.aws_ec2_security_group_name : "SG for ${var.aws_resource_identifier} - EC2"
  description = "SG for ${var.aws_resource_identifier} - EC2"
  vpc_id      = var.aws_ec2_selected_vpc_id
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "${var.aws_resource_identifier}-ec2-sg"
  }
}

# This is needed for Ansible to connect
resource "aws_security_group_rule" "ingress_ssh" {
  type              = "ingress"
  description       = "SSH"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.ec2_security_group.id
}

resource "aws_security_group_rule" "incoming_ports" {
  count             = length(local.aws_ec2_port_list) != 0 ? length(local.aws_ec2_port_list) : 0
  type              = "ingress"
  from_port         = local.aws_ec2_port_list[count.index]
  to_port           = local.aws_ec2_port_list[count.index]
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.ec2_security_group.id
}

locals {
  aws_ec2_port_list = var.aws_ec2_port_list != "" ? [for n in split(",", var.aws_ec2_port_list) : tonumber(n)] : []
}

resource "aws_iam_role" "ec2_role" {
  count = var.aws_ec2_iam_instance_profile != "" ? 0 : 1
  name  = var.aws_resource_identifier
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

# attach a policy to allow cloudwatch access
resource "aws_iam_policy" "cloudwatch" {
  count = var.aws_ec2_iam_instance_profile != "" ? 0 : 1
  name  = var.aws_resource_identifier

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents",
                "logs:DescribeLogStreams"
            ],
            "Resource": [
                "*"
            ]
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "cloudwatch_attach" {
  count      = var.aws_ec2_iam_instance_profile != "" ? 0 : 1
  role       = aws_iam_role.ec2_role[0].name
  policy_arn = aws_iam_policy.cloudwatch[0].arn
}