resource "local_file" "aws_efs" {
    filename = format("%s/%s", abspath(path.root), "aws_efs.tf")
    content = file(format("%s/%s", abspath(path.module), "aws_efs.tmpl"))
}