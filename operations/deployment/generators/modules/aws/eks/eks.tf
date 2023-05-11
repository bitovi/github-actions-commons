resource "local_file" "aws_eks_foo" {
    filename = format("%s/%s", abspath(path.root), "bitovi_aws_eks.tf")
    content = file(format("%s/%s", abspath(path.module), "aws_eks.tmpl"))
}