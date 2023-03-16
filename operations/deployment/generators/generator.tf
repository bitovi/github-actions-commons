module "aws_defauts" {
  source = "./modules/aws/aws_defaults"
}

module "certificates" {
  source = "./modules/aws/certificates"
}

module "ec2" {
  source = "./modules/aws/ec2"
}

module "efs" {
  source = "./modules/aws/efs"
}

module "elb" {
  source = "./modules/aws/elb"
}

module "exports" {
  source = "./modules/aws/exports"
}

module "rds" {
  source = "./modules/aws/rds"
}

module "route53" {
  source = "./modules/aws/route53"
}

module "ansible" {
  source = "./modules/ansible/"
}
