module "aws_defauts" {
  count  = local.aws_in_usage
  source = "./modules/aws/aws_defaults"
}

module "certificates" {
  count  = var.aws_r53_enable_cert == "true" ? 1 : 0
  source = "./modules/aws/certificates"
}

module "ec2" {
  count  = var.aws_ec2_instance_create == "true" ? 1 : 0
  source = "./modules/aws/ec2"
}

module "efs" {
  count  = var.aws_efs_create == "true" ? 1 : 0
  source = "./modules/aws/efs"
}

module "elb" {
  count  = var.aws_elb_create == "true" ? 1 : 0
  source = "./modules/aws/elb"
}

module "exports" {
  count  = var.env_aws_secret != "" ? 1 : 0
  source = "./modules/aws/exports"
}

module "rds" {
  count  = var.aws_postgres_enable == "true" ? 1 : 0
  source = "./modules/aws/rds"
}

module "route53" {
  count  = var.aws_r53_enable == "true" ? 1 : 0
  source = "./modules/aws/route53"
}

module "ansible" {
  count  = var.docker_install == "true" ? 1 : var.st2_install == "true" ? 1 : 0
  source = "./modules/ansible/aws"
}

locals {
  aws_in_usage = (
    var.aws_r53_enable_cert == "true" ? 1 :
    ( var.aws_ec2_instance_create == "true" ? 1 : 
      ( var.aws_efs_create == "true" ? 1 : 
        ( var.aws_elb_create == "true" ? 1 :
          ( var.aws_postgres_enable == "true" ? 1 :
            ( var.aws_r53_enable == "true" ? 1 : 0 )
          )
        )
      )
    )
  )
}