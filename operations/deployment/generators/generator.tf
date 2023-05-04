module "aws_defauts" {
  #count  = local.aws_in_usage
  source = "./modules/aws/aws_defaults"
}

module "certificates" {
  count  = var.aws_r53_enable_cert ? 1 : 0
  source = "./modules/aws/certificates"
}

module "ec2" {
  #count  = var.aws_ec2_instance_create ? 1 : 0
  source = "./modules/aws/ec2"
  aws_ec2_ami_update = var.aws_ec2_ami_update
}

module "ec2_efs" {
  #count  = local.enable_efs ? 1 : 0
  source = "./modules/aws/ec2_efs"
}

module "efs" {
  #count  = local.enable_efs ? 1 : 0
  source = "./modules/aws/efs"
}

module "elb" {
  count  = var.aws_elb_create ? (var.aws_ec2_instance_create ? 1 : 0) : 0
  source = "./modules/aws/elb"
  aws_r53_enable_cert = var.aws_r53_enable_cert
}

module "exports" {
  count  = local.aws_in_usage
  source = "./modules/aws/exports"
  env_aws_secret = var.env_aws_secret
}

module "rds" {
  #count  = var.aws_postgres_enable ? 1 : 0
  source = "./modules/aws/rds"
}

module "route53" {
  count  = var.aws_r53_enable ? 1 : 0
  source = "./modules/aws/route53"
  aws_r53_enable_cert = var.aws_r53_enable_cert
}

module "ansible" {
  count  = var.ansible_skip ? 0 : 1
  source = "./modules/ansible/aws"
  aws_ec2_instance_public_ip = var.aws_ec2_instance_public_ip
  enable_efs = local.enable_efs
}

locals {
  aws_in_usage = (
    var.aws_r53_enable_cert ? 1 :
    ( var.aws_ec2_instance_create ? 1 : 
      ( local.enable_efs ? 1 : 
        ( var.aws_elb_create ? 1 :
          ( var.aws_postgres_enable ? 1 :
            ( var.aws_r53_enable ? 1 : 0 )
          )
        )
      )
    )
  )
  enable_efs = (
    var.aws_efs_create || var.aws_efs_create_ha || var.aws_efs_mount_id != "" ? true : false
  )
}