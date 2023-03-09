#resource "local_file" "aws_dotenv_postgres" {
#    filename = format("%s/%s", abspath(path.root), "aws_dotenv_postgres.tf")
#    content  = file("${path.module}/aws/aws_dotenv_postgres.tmpl")
#}
#
#resource "local_file" "aws_00_default_tags" {
#    filename = format("%s/%s", abspath(path.root), "aws_00_default_tags.tf")
#    content  = file("${path.module}/aws/aws_00_default_tags.tmpl")
#}
#
#resource "local_file" "aws_00_default_tags" {
#    filename = format("%s/%s", abspath(path.root), "aws_00_default_tags.tf")
#    content  = file("${path.module}/aws/aws_00_default_tags.tmpl")
#}
#