resource "local_file" "aws_elb_no_cert" {
    filename = format("%s/%s", abspath(path.root), "aws_elb_no_cert.tf")
    content = file(format("%s/%s", abspath(path.module), "aws_elb_no_cert.tmpl"))
}