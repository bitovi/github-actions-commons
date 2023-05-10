resource "local_file" "aws_default_tags" {
    filename = format("%s/%s", abspath(path.root), "bitovi_aws_default_tags.tf")
    content = file(format("%s/%s", abspath(path.module), "aws_default_tags.tmpl"))
}

resource "local_file" "aws_azs_sn_sg" {
    filename = format("%s/%s", abspath(path.root), "bitovi_aws_default_vpc_subnet_sg.tf")
    content = file(format("%s/%s", abspath(path.module), "aws_default_vpc_subnet_sg.tmpl"))
}