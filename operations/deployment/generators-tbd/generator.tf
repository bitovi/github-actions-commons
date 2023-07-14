module "ec2" {
  source = "./modules/aws/ec2"
  aws_ec2_ami_update = var.aws_ec2_ami_update
}