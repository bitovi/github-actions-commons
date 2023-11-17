resource "local_file" "file_dotenv" {
  filename = format("%s/%s", abspath(path.root), var.filename)
  content  = sensitive(var.content)
}

variable "content" {
  type = string
}

variable "filename" {
  type = string
}