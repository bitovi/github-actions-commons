resource "aws_iam_instance_profile" "inst_profile" {
  name = var.iam_instance_profile_name
  path = "/"
  role = var.iam_role_name
  depends_on  = [var.iaminstprofile_depends_on]
}

output "instance_profile_name" {
  value = aws_iam_instance_profile.inst_profile.name
}