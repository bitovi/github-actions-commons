resource "local_file" "aws_elb_with_cert" {
    filename = format("%s/%s", abspath(path.root), "aws_elb_with_cert.tf")
    content = file(format("%s/%s", abspath(path.module), "aws_elb_with_cert.tmpl"))
}