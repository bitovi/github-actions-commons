resource "local_file" "aws_ec2_efs" {
    filename = format("%s/%s", abspath(path.root), "bitovi_aws_ec2_efs.tf")
    content = file(format("%s/%s", abspath(path.module), "aws_ec2_efs.tmpl"))
}

resource "local_file" "aws_dotenv_efs" {
    filename = format("%s/%s", abspath(path.root), "bitovi_aws_dotenv_efs.tf")
    content  = file(format("%s/%s", abspath(path.module), "aws_dotenv_efs.tmpl"))
}