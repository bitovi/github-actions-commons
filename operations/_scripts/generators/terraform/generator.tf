module "aws_defauts" {
  source = "./modules/aws/aws_defaults"
}

module "aws_certificates" {
  source = "./modules/aws/certificates"
}

module "aws_ec2" {
  source = "./modules/aws/ec2"
}

module "aws_efs" {
  source = "./modules/aws/efs"
}

module "aws_elb" {
  source = "./modules/aws/elb"
}

module "aws_route53" {
  source = "./modules/aws/route53"
}
