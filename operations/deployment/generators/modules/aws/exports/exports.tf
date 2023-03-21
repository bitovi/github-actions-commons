resource "local_file" "aws_dotenv_secretmanager" {
    filename = format("%s/%s", abspath(path.root), "aws_dotenv_secretmanager.tf")
    content = file(format("%s/%s", abspath(path.module), "aws_dotenv_secretmanager.tmpl"))
}