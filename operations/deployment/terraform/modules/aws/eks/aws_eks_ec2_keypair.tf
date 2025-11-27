resource "tls_private_key" "key" {
  count     = var.aws_eks_ec2_key_pair == "" ? 1 : 0
  algorithm = "RSA"
  rsa_bits  = 4096
}

// Creates an ec2 key pair using the tls_private_key.key public key
resource "aws_key_pair" "aws_key" {
  count      = var.aws_eks_ec2_key_pair == "" ? 1 : 0
  key_name   = "${var.aws_resource_identifier}-ec2kp-eks-${random_string.random.result}"
  public_key = tls_private_key.key[0].public_key_openssh
}

// Creates a secret manager secret for the public key
resource "aws_secretsmanager_secret" "keys_sm_secret" {
  count = var.aws_eks_ec2_key_pair == "" ? (var.aws_eks_store_keypair_sm ? 1 : 0) : 0
  name  = "${var.aws_resource_identifier}-ec2kp-eks-${random_string.random.result}"
}

resource "aws_secretsmanager_secret_version" "keys_sm_secret_version" {
  count         = var.aws_eks_ec2_key_pair == "" ? (var.aws_eks_store_keypair_sm ? 1 : 0) : 0
  secret_id     = aws_secretsmanager_secret.keys_sm_secret[0].id
  secret_string = <<EOF
   {
    "key": "public_key",
    "value": "${sensitive(tls_private_key.key[0].public_key_openssh)}"
   },
   {
    "key": "private_key",
    "value": "${sensitive(tls_private_key.key[0].private_key_openssh)}"
   }
EOF
}

resource "random_string" "random" {
  length  = 5
  lower   = true
  special = false
  numeric = false
  lifecycle {
    ignore_changes = all
  }
}