resource "local_file" "aws_certificates" {
    filename = format("%s/%s", abspath(path.root), "bitovi_aws_certificates.tf")
    content = file(format("%s/%s", abspath(path.module), "aws_certificates.tmpl"))
}
