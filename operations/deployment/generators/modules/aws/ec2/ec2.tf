resource "local_file" "aws_ec2_iam_profile" {
    filename = format("%s/%s", abspath(path.root), "aws_ec2_iam_profile.tf")
    content = file(format("%s/%s", abspath(path.module), "aws_ec2_iam_profile.tmpl"))
}

resource "local_file" "aws_ec2_security_group" {
    filename = format("%s/%s", abspath(path.root), "aws_ec2_security_group.tf")
    content = file(format("%s/%s", abspath(path.module), "aws_ec2_security_group.tmpl"))
}

#resource "local_file" "aws_ec2" {
#    filename = format("%s/%s", abspath(path.root), "aws_ec2.tf")
#    content = file(format("%s/%s", abspath(path.module), "aws_ec2.tmpl"))
#}

resource "local_file" "aws_ec2" {
    filename = format("%s/%s", abspath(path.root), "aws_ec2.tf")
    content  = templatefile(format("%s/%s", abspath(path.module), "aws_ec2.tmpl"), {
      lifecycle_content = var.aws_ec2_ami_update ? null : "ami"
    })
}

resource "local_file" "aws_dotenv_ec2" {
    filename = format("%s/%s", abspath(path.root), "aws_dotenv_ec2.tf")
    content  = file(format("%s/%s", abspath(path.module), "aws_dotenv_ec2.tmpl"))
}

variable "aws_ec2_ami_update" {
  type        = bool
  default     = false
}