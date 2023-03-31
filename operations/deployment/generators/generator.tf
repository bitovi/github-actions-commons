module "aws_defauts" {
  count  = local.aws_in_usage
  source = "./modules/aws/aws_defaults"
}

module "certificates" {
  count  = var.aws_r53_enable_cert ? 1 : 0
  source = "./modules/aws/certificates"
}

module "ec2" {
  count  = var.aws_ec2_instance_create ? 1 : 0
  source = "./modules/aws/ec2"
}

module "efs" {
  count  = var.aws_efs_create || var.aws_efs_create_ha ? 1 : 0
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
  env_aws_secret          = var.env_aws_secret
}

module "rds" {
  count  = var.aws_postgres_enable ? 1 : 0
  source = "./modules/aws/rds"
}

module "route53" {
  count  = var.aws_r53_enable ? 1 : 0
  source = "./modules/aws/route53"
  aws_r53_enable_cert = var.aws_r53_enable_cert
}

module "ansible" {
  count  = var.docker_install ? 1 : var.st2_install ? 1 : 0
  source = "./modules/ansible/aws"
  aws_ec2_instance_public_ip = var.aws_ec2_instance_public_ip
  aws_efs_create = var.aws_efs_create
  aws_efs_create_ha = var.aws_efs_create_ha
}

locals {
  aws_in_usage = (
    var.aws_r53_enable_cert ? 1 :
    ( var.aws_ec2_instance_create ? 1 : 
      ( var.aws_efs_create || var.aws_efs_create_ha ? 1 : 
        ( var.aws_elb_create ? 1 :
          ( var.aws_postgres_enable ? 1 :
            ( var.aws_r53_enable ? 1 : 0 )
          )
        )
      )
    )
  )
  
}