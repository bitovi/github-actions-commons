resource "local_file" "aws_dotenv_postgres" {
    filename = format("%s/%s", abspath(path.root), "aws_dotenv_postgres.tf")
    content = file(format("%s/%s", abspath(path.module), "aws_dotenv_postgres.tmpl"))
}

resource "local_file" "aws_postgres" {
    filename = format("%s/%s", abspath(path.root), "aws_postgres.tf")
    content = file(format("%s/%s", abspath(path.module), "aws_postgres.tmpl"))
}