resource "local_file" "aws_elb" {
    filename = format("%s/%s", abspath(path.root), "aws_elb.tf")
    content = file(format("%s/%s", abspath(path.module), "aws_elb.tmpl"))
}