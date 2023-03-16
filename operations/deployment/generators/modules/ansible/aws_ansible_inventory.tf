resource "local_file" "aws_ansible_inventory" {
    filename = format("%s/%s", abspath(path.root), "aws_ansible_inventory.tf")
    content = file(format("%s/%s", abspath(path.module), "aws_ansible_inventory.tmpl"))
}