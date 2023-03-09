resource "local_file" "aws_default_tags" {
    filename = format("%s/%s", abspath(path.root), "aws_default_tags.tf")
    content = file(format("%s/%s", abspath(path.module), "aws_default_tags.tmpl"))
}
