resource "local_file" "aws_default_tags" {
    filename = format("%s/%s", abspath(path.root), "aws_default_tags.tf")
    content = file(format("%s/%s", abspath(path.module), "aws_default_tags.tmpl"))
}

resource "local_file" "aws_azs_sn_sg" {
    filename = format("%s/%s", abspath(path.root), "aws_azs_sn_sg.tf")
    content = file(format("%s/%s", abspath(path.module), "aws_azs_sn_sg.tmpl"))
}

#resource "local_file" "aws_locals" {
#    filename = format("%s/%s", abspath(path.root), "aws_locals.tf")
#    content = file(format("%s/%s", abspath(path.module), "aws_locals.tmpl"))
#}