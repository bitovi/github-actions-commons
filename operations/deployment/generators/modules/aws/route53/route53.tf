resource "local_file" "aws_route53" {
    filename = format("%s/%s", abspath(path.root), "aws_route53.tf")
    content = file(format("%s/%s", abspath(path.module), "aws_route53.tmpl"))
}