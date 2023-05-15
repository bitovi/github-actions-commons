locals {
  #general config

  aws-profile   = var.aws-profile
  aws-region    = var.aws-region
  environment   = var.environment
  account_id    = var.account_id
  stackname     = var.stackname
  subsystem_val = "primary"
  #reponame = "bitovi/operations-recruiting"

  #vpc related config values
  vpc_name                = "${local.stackname}-${local.subsystem_val}-vpc"
  vpc_cidr                = var.cidr_block
  availability_zones      = var.availability_zones
  private_subnets         = var.private_subnets
  public_subnets          = var.public_subnets
  kubernetes_cluster_name = "${local.environment}-ekscluster"

  #Userdata for nodes
  node-userdata = <<USERDATA
  #!/bin/bash
  set -o xtrace
  # These are used to install SSM Agent to SSH into the EKS nodes.
  sudo yum install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm
  systemctl enable amazon-ssm-agent
  systemctl restart amazon-ssm-agent
  /etc/eks/bootstrap.sh --apiserver-endpoint '${module.eks_master.eks_master_endpoint}' --b64-cluster-ca '${module.eks_master.cluster_certificate_authority_data}' '${local.kubernetes_cluster_name}'
  # Retrieve the necessary packages for `mount` to work properly with NFSv4.1
  sudo yum update -y
  sudo yum install -y amazon-efs-utils nfs-utils nfs-utils-lib
  # after the eks bootstrap and necessary packages installation - restart kubelet
  systemctl restart kubelet.service
  USERDATA


  #Worker node launch config
  instance_type               = var.instance_type
  name_prefix                 = "${local.environment}-eksworker"
  # name                        = "${local.environment}-eksworker"
  associate_public_ip_address = true

  # from: https://console.aws.amazon.com/systems-manager/parameters/%252Faws%252Fservice%252Feks%252Foptimized-ami%252F1.19%252Famazon-linux-2%252Frecommended%252Fimage_id/description?region=us-east-2#
  # https://docs.aws.amazon.com/eks/latest/userguide/eks-optimized-ami.html
  image_id                    = var.image_id
  user_data_base64            = base64encode(local.node-userdata)
  cluster_version             = var.cluster_version

  #Worker node asg config
  ec2_key_pair     = "bitovi-devops-deploy-eks"
  desired_capacity = var.desired_capacity
  max_size         = var.max_size
  min_size         = var.max_size
  asg_name         = "${local.environment}-eksworker"
  workstation_cidr = var.workstation_cidr


  common_tags = {
    "terraform"        = "true"
    #RepoName           = "${local.reponame}"
    OpsRepoEnvironment = "${local.environment}"
    OpsRepoApp         = "${local.stackname}"
  }
}

## data lookups
/* 
data "aws_ami" "eks-worker" {
  filter {
    name   = "name"
    values = ["amazon-eks-node-${module.eks_master.cluster_version}-v*"]
  }

  most_recent = true
  owners      = ["755521597925"] # Amazon EKS AMI Account ID
} */
