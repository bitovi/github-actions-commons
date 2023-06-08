resource "local_file" "aws_eks_iam" {
    filename = format("%s/%s", abspath(path.root), "bitovi_aws_eks_iam.tf")
    content = file(format("%s/%s", abspath(path.module), "aws_eks_iam.tmpl"))
}

resource "local_file" "aws_eks_nodes" {
    filename = format("%s/%s", abspath(path.root), "bitovi_aws_eks_nodes.tf")
    content = file(format("%s/%s", abspath(path.module), "aws_eks_nodes.tmpl"))
}

resource "local_file" "aws_eks_security_group" {
    filename = format("%s/%s", abspath(path.root), "bitovi_aws_eks_security_group.tf")
    content = file(format("%s/%s", abspath(path.module), "aws_eks_security_group.tmpl"))
}

resource "local_file" "aws_eks_vpc" {
    filename = format("%s/%s", abspath(path.root), "bitovi_aws_eks_vpc.tf")
    content = file(format("%s/%s", abspath(path.module), "aws_eks_vpc.tmpl"))
}