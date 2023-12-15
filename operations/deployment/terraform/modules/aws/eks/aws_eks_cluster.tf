locals {
  aws_eks_cluster_log_types = var.aws_eks_cluster_log_types != "" ? [for n in split(",", var.aws_eks_cluster_log_types) : (n)] : []
}

resource "aws_eks_cluster" "main" {
  name     = var.aws_eks_cluster_name # Cluster name is defined during the code-generation phase
  version  = var.aws_eks_cluster_version
  role_arn = aws_iam_role.iam_role_master.arn
  vpc_config {
    security_group_ids      = [aws_security_group.eks_security_group_master.id]
    subnet_ids              = data.aws_subnets.public.ids
    endpoint_private_access = false
    endpoint_public_access  = true
  }

  depends_on = [
    aws_iam_role.iam_role_master,
    aws_security_group.eks_security_group_master,
    aws_iam_role_policy_attachment.managed_policies_master,
    aws_iam_role_policy_attachment.managed_policies_worker
  ]
  enabled_cluster_log_types = local.aws_eks_cluster_log_types

  tags = {
    "kubernetes.io/cluster/${var.aws_eks_cluster_name}" = "owned"
  }
}

data "aws_subnets" "private" {
  filter {
    name    = "vpc-id"
    values = [var.aws_selected_vpc_id]
  }
  tags = {
    Tier = "Private"
  }
}

data "aws_subnets" "public" {
  filter {
    name   = "vpc-id"
    values = [var.aws_selected_vpc_id]
  }
  tags = {
    Tier = "Public"
  }
}

data "aws_eks_cluster" "eks_cluster" {
  name = aws_eks_cluster.main.id
}

data "aws_eks_cluster_auth" "cluster_auth" {
  name = aws_eks_cluster.main.id
}

resource "aws_launch_template" "main" {
  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.eks_security_group_worker.id]
  }
  #iam_instance_profile {
  #  name = aws_iam_instance_profile.eks_inst_profile.name
  #}
  image_id                    = var.aws_eks_instance_ami_id != "" ? var.aws_eks_instance_ami_id : data.aws_ami.image_selected.id
  instance_type               = var.aws_eks_instance_type
  name_prefix                 = "${var.aws_eks_environment}-eksworker"
  user_data                   = base64encode(try(file("./aws_ec2_incoming_user_data_script.sh"), (var.aws_eks_instance_ami_id != "" ? local.node-userdata : "" )))
  key_name                    = var.aws_eks_ec2_key_pair != "" ? var.aws_eks_ec2_key_pair : aws_key_pair.aws_key[0].id
  update_default_version = true
  lifecycle {
    create_before_destroy = true
  }
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "optional"
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "enabled"
  }
}

data "aws_ami" "image_selected" {
  most_recent = true
  owners = ["amazon"]

  filter {
    name   = "name"
    values = ["amazon-eks-node-${var.aws_eks_cluster_version}*"]
  }
}


locals {
  #Userdata for nodes
  node-userdata = <<USERDATA
  #!/bin/bash
  set -o xtrace
  # These are used to install SSM Agent to SSH into the EKS nodes.
  sudo yum install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm
  systemctl enable amazon-ssm-agent
  systemctl restart amazon-ssm-agent
  /etc/eks/bootstrap.sh --apiserver-endpoint '${resource.aws_eks_cluster.main.endpoint}' --b64-cluster-ca '${resource.aws_eks_cluster.main.certificate_authority.0.data}' '${resource.aws_eks_cluster.main.name}'
  # Retrieve the necessary packages for `mount` to work properly with NFSv4.1
  sudo yum update -y
  sudo yum install -y amazon-efs-utils nfs-utils nfs-utils-lib
  # after the eks bootstrap and necessary packages installation - restart kubelet
  systemctl restart kubelet.service
  # Take care of instance name by adding the launch order  
  INSTANCE_NAME_TAG=$(curl -s http://169.254.169.254/latest/meta-data/tags/instance/Name)
  LOCAL_IP=$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)
  # Get Instance MetaData
  REGION=$(curl -s http://169.254.169.254/latest/meta-data/placement/region)
  INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
  aws ec2 create-tags --region $REGION --resources $INSTANCE_ID --tags Key=Name,Value=$INSTANCE_NAME_TAG-$LOCAL_IP
  USERDATA
}

#resource "aws_autoscaling_group" "main" {
#  desired_capacity     = var.aws_eks_desired_capacity
#  launch_template {
#    id      = aws_launch_template.main.id
#    version = "${aws_launch_template.main.latest_version}"
#  }
#  max_size             = var.aws_eks_max_size
#  min_size             = var.aws_eks_min_size
#  name                 = "${var.aws_resource_identifier}-${var.aws_eks_environment}-eksworker-asg"
#  vpc_zone_identifier  = data.aws_subnets.private.ids
#  health_check_type    = "EC2"
#
#tag {
#  key                 = "Name"
#  value               = "${var.aws_resource_identifier}-${var.aws_eks_environment}-eksworker-node"
#  propagate_at_launch = true
#}
#
#  depends_on = [
#    aws_iam_role.iam_role_master,
#    aws_iam_role.iam_role_worker,
#    aws_security_group.eks_security_group_master,
#    aws_security_group.eks_security_group_worker
#  ]
#}

resource "aws_eks_node_group" "worker_nodes" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${var.aws_resource_identifier}-${var.aws_eks_environment}-eksworker-node-group"
  node_role_arn   = aws_iam_role.iam_role_worker.arn
  subnet_ids      = data.aws_subnets.private.ids

  scaling_config {
    desired_size = var.aws_eks_desired_capacity
    max_size     = var.aws_eks_max_size
    min_size     = var.aws_eks_min_size
  }

  update_config {
    max_unavailable = 1
  }

  launch_template {
    id      = aws_launch_template.main.id
    version = "${aws_launch_template.main.latest_version}"
  }

  depends_on = [
    aws_eks_cluster.main,
    aws_iam_role.iam_role_worker,
    aws_launch_template.main,
  ]
}

output "aws_eks_cluster_name" {
  value = aws_eks_cluster.main.name
}

output "aws_eks_cluster_role_arn" {
  value = aws_eks_cluster.main.role_arn
}

output "private_subnets" {
  value = data.aws_subnets.private.ids
}

output "eks_host" {
  value = data.aws_eks_cluster.eks_cluster.endpoint
}

output "eks_cluster_ca_certificate" {
  value = base64decode(data.aws_eks_cluster.eks_cluster.certificate_authority.0.data)
}

output "eks_token" {
  value = data.aws_eks_cluster_auth.cluster_auth.token
}
