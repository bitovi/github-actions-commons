resource "aws_iam_instance_profile" "ec2_profile" {
  name = var.aws_resource_identifier
  role = aws_iam_role.ec2_role.name
}

data "aws_ami" "image_selected" {
  most_recent = true
  filter {
    name   = "name"
    values = ["${var.aws_ec2_ami_filter}"]
  }
  owners = ["${var.aws_ec2_ami_owner}"]
}

resource "aws_instance" "server" {
  count                       = var.aws_ec2_ami_update ? 1 : 0
  ami                         = var.aws_ec2_ami_id != "" ? var.aws_ec2_ami_id : data.aws_ami.image_selected.id
  availability_zone           = var.preferred_az
  subnet_id                   = var.aws_subnet_selected_id
  instance_type               = var.aws_ec2_instance_type
  associate_public_ip_address = var.aws_ec2_instance_public_ip
  vpc_security_group_ids      = [aws_security_group.ec2_security_group.id]
  key_name                    = aws_key_pair.aws_key.key_name
  monitoring                  = true
  iam_instance_profile        = aws_iam_instance_profile.ec2_profile.name
  user_data_base64            = base64encode(try(file("./aws_ec2_incoming_user_data_script.sh"), ""))
  user_data_replace_on_change = var.aws_ec2_user_data_replace_on_change
  root_block_device {
    volume_size           = tonumber(var.aws_ec2_instance_root_vol_size)
    delete_on_termination = var.aws_ec2_instance_root_vol_preserve ? false : true
#    tags                  = var.ec2_tags
  }
  tags = {
    Name = "${var.aws_resource_identifier} - Instance"
  }
  volume_tags = var.ec2_tags
}

output "ec2_tags" {
  value = var.ec2_tags
}

data "aws_instance" "server_ip" {
  count       = var.aws_ec2_ami_update ? 1 : 0
  instance_id = aws_instance.server[0].id
  depends_on  = [ aws_instance.server ]
}

resource "aws_instance" "server_ignore_ami" {
  count                       = var.aws_ec2_ami_update ? 0 : 1
  ami                         = var.aws_ec2_ami_id != "" ? var.aws_ec2_ami_id : data.aws_ami.image_selected.id
  availability_zone           = var.preferred_az
  subnet_id                   = var.aws_subnet_selected_id
  instance_type               = var.aws_ec2_instance_type
  associate_public_ip_address = var.aws_ec2_instance_public_ip
  vpc_security_group_ids      = [aws_security_group.ec2_security_group.id]
  key_name                    = aws_key_pair.aws_key.key_name
  monitoring                  = true
  iam_instance_profile        = aws_iam_instance_profile.ec2_profile.name
  user_data_base64            = base64encode(try(file("./aws_ec2_incoming_user_data_script.sh"), ""))
  user_data_replace_on_change = var.aws_ec2_user_data_replace_on_change
  root_block_device {
    volume_size           = tonumber(var.aws_ec2_instance_root_vol_size)
    delete_on_termination = var.aws_ec2_instance_root_vol_preserve ? false : true
  }
  tags = {
    Name = "${var.aws_resource_identifier} - Instance"
  }
  lifecycle {
    ignore_changes = [ami]
  }
}

data "aws_instance" "server_ignore_ami_ip" {
  count      = var.aws_ec2_ami_update ? 0 : 1
  instance_id = aws_instance.server_ignore_ami[0].id
  depends_on  = [ aws_instance.server_ignore_ami ]
}

resource "tls_private_key" "key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_sensitive_file" "private_key" {
  content         = tls_private_key.key.private_key_pem
  filename        = format("%s/%s/%s", abspath(path.root), ".ssh", "bitops-ssh-key.pem")
  file_permission = "0600"
}

// Creates an ec2 key pair using the tls_private_key.key public key
resource "aws_key_pair" "aws_key" {
  key_name   = "${var.aws_resource_identifier_supershort}-ec2kp-${random_string.random.result}"
  public_key = tls_private_key.key.public_key_openssh
}

// Creates a secret manager secret for the public key
resource "aws_secretsmanager_secret" "keys_sm_secret" {
  count  = var.aws_ec2_create_keypair_sm ? 1 : 0
  name   = "${var.aws_resource_identifier_supershort}-sm-${random_string.random.result}"
  lifecycle {
    replace_triggered_by = [tls_private_key.key]
  }
}
 
resource "aws_secretsmanager_secret_version" "keys_sm_secret_version" {
  count     = var.aws_ec2_create_keypair_sm ? 1 : 0
  secret_id = aws_secretsmanager_secret.keys_sm_secret[0].id
  secret_string = <<EOF
   {
    "key": "public_key",
    "value": "${sensitive(tls_private_key.key.public_key_openssh)}"
   },
   {
    "key": "private_key",
    "value": "${sensitive(tls_private_key.key.private_key_openssh)}"
   }
EOF
}

resource "random_string" "random" {
  length    = 5
  lower     = true
  special   = false
  numeric   = false
}

output "instance_public_dns" {
  description = "Public DNS address of the EC2 instance"
  value       = var.aws_ec2_instance_public_ip ? try(data.aws_instance.server_ip[0].public_dns,data.aws_instance.server_ignore_ami_ip[0].public_dns) : "EC2 Instance doesn't have public IP address"
}

output "instance_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = try(data.aws_instance.server_ip[0].public_ip,data.aws_instance.server_ignore_ami_ip[0].public_ip)
}

output "aws_instance_server_id" {
  value = try(data.aws_instance.server_ip[0].id,data.aws_instance.server_ignore_ami_ip[0].id)
}

output "private_key_filename" {
  value = local_sensitive_file.private_key.filename
}