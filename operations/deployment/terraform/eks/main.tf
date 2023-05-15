module "eks_vpc" {
  source = "./modules/vpc"
  #create_vpc               = true
  vpc_name                = local.vpc_name
  cidr                    = local.vpc_cidr
  availability_zones      = local.availability_zones
  private_subnets         = local.private_subnets
  public_subnets          = local.public_subnets
  kubernetes_cluster_name = local.kubernetes_cluster_name
  environment             = local.environment
  common_tags             = local.common_tags
}

module "eks_master_role" {
  source                   = "./modules/iamrole"
  iam_role_name            = "${local.environment}-eksmaster"
  iam_assume_role_filename = "assumerole-eksmaster-trusted-entities.json"
  iam_role_policy_name     = "${local.environment}-eksmaster"
  iam_role_policy_filename = "assumerole-eksmaster-policy.json"
  managed_policies = ["arn:aws:iam::aws:policy/AmazonEKSClusterPolicy",
  "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"]
  common_tags              = local.common_tags
}

module "master_securitygroup" {
  source                    = "./modules/securitygroup"
  securitygroup_name        = "${local.environment}-master-sg"
  securitygroup_description = "Cluster communication with worker nodes"
  vpc_id                    = module.eks_vpc.vpc_id
  kubernetes_cluster_name   = local.kubernetes_cluster_name
  #ingress_cidr_blocks       = module.eks_vpc.private_subnets_cidr_blocks
  sg_depends_on = [module.eks_vpc]
  common_tags               = local.common_tags
}

module "master_securitygroup_rule1" {
  source         = "./modules/securitygroupidrule"
  sg_description = "Allow pods to communicate with the cluster API Server"
  type           = "ingress"
  from_port      = "443"
  to_port        = "443"
  protocol       = "tcp"
  source_sg_id   = module.worker_securitygroup.sg_id
  sg_id          = module.master_securitygroup.sg_id
  common_tags    = local.common_tags
}

module "master_securitygroup_rule2" {
  source         = "./modules/securitygroupidrule"
  sg_description = "Allow self communication with in master"
  type           = "ingress"
  from_port      = "0"
  to_port        = "0"
  protocol       = "-1"
  source_sg_id   = module.master_securitygroup.sg_id
  sg_id          = module.master_securitygroup.sg_id
  common_tags    = local.common_tags
}

module "master_securitygroup_rule3" {
  source         = "./modules/securitygrouprule"
  sg_description = "Allow workstation or EC2 to communicate with the cluster API Server"
  type           = "ingress"
  from_port      = "443"
  to_port        = "443"
  protocol       = "tcp"
  cidr           = local.workstation_cidr
  sg_id          = module.master_securitygroup.sg_id
  common_tags    = local.common_tags
}


module "eks_master" {
  source                  = "./modules/eks-master"
  cluster_name            = local.kubernetes_cluster_name
  k8s_master_version      = local.cluster_version
  role_arn                = module.eks_master_role.iam_role_arn
  security_group_ids      = [module.master_securitygroup.sg_id]
  subnet_ids              = module.eks_vpc.public_subnets
  endpoint_private_access = false
  endpoint_public_access  = true
  eks_depends_on = [module.eks_vpc,
    module.eks_master_role,
  module.master_securitygroup]
  common_tags             = local.common_tags
}

module "eks_worker_role" {
  source                   = "./modules/iamrole"
  iam_role_name            = "${local.environment}-eksworker"
  iam_assume_role_filename = "assumerole-eksworker-trusted-entities.json"
  iam_role_policy_name     = "${local.environment}-eksworker"
  iam_role_policy_filename = "assumerole-eksworker-policy.json"
  managed_policies = ["arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
  "arn:aws:iam::aws:policy/AmazonEC2FullAccess"]
  common_tags              = local.common_tags
}

module "eks_worker_instprofile" {
  source                    = "./modules/iaminstanceprofile"
  iam_role_name             = "${local.environment}-eksworker"
  iam_instance_profile_name = "${local.environment}-instprofile"
  iaminstprofile_depends_on = [module.eks_worker_role]
  common_tags               = local.common_tags
}

module "worker_securitygroup" {
  source                    = "./modules/securitygroup"
  securitygroup_name        = "${local.environment}-worker-sg"
  securitygroup_description = "Security group for all nodes in the cluster"
  vpc_id                    = module.eks_vpc.vpc_id
  kubernetes_cluster_name   = local.kubernetes_cluster_name
  sg_depends_on             = [module.eks_vpc]
  common_tags               = local.common_tags
}




module "worker_securitygroup_rule1" {
  source         = "./modules/securitygroupidrule"
  sg_description = "Allow node to communication with each other and self"
  type           = "ingress"
  from_port      = "0"
  to_port        = "65535"
  protocol       = "-1"
  source_sg_id   = module.worker_securitygroup.sg_id
  sg_id          = module.worker_securitygroup.sg_id
  common_tags    = local.common_tags
}

module "worker_securitygroup_rule2" {
  source         = "./modules/securitygroupidrule"
  sg_description = "Allow worker Kubelets and pods to receive communication from the cluster control plane"
  type           = "ingress"
  from_port      = "1025"
  to_port        = "65535"
  protocol       = "tcp"
  source_sg_id   = module.master_securitygroup.sg_id
  sg_id          = module.worker_securitygroup.sg_id
  common_tags    = local.common_tags
}

module "eks_worker" {
  source                      = "./modules/eks-nodes"
  associate_public_ip_address = local.associate_public_ip_address
  iam_instance_profile        = module.eks_worker_instprofile.instance_profile_name
  image_id                    = local.image_id
  instance_type               = local.instance_type
  name_prefix                 = local.name_prefix
  security_groups             = [module.worker_securitygroup.sg_id]
  user_data_base64            = local.user_data_base64
  ec2_key_pair                = local.ec2_key_pair
  desired_capacity            = local.desired_capacity
  max_size                    = local.max_size
  min_size                    = local.min_size
  asg_name                    = local.asg_name
  vpc_zone_identifier         = module.eks_vpc.private_subnets
  cluster_name                = local.kubernetes_cluster_name
  eks_worker_depends_on       = [ module.eks_vpc,
                                  module.eks_master_role,
                                  module.eks_worker_role,
                                  module.eks_worker_instprofile,
                                  module.master_securitygroup,
                                  module.worker_securitygroup
                                ]
  common_tags                 = local.common_tags
}