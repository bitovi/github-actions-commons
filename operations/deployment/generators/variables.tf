variable "aws_ec2_ami_update" {
  type        = bool
  description = "Recreates the EC2 instance if there is a newer version of the AMI"
  default     = false
}