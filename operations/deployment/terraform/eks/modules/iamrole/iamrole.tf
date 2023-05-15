resource "aws_iam_role" "iam_role" {
  name               = var.iam_role_name
  assume_role_policy = file("policies/${var.iam_assume_role_filename}")
}

resource "aws_iam_role_policy" "iam_role_policy" {
  name   = var.iam_role_policy_name
  policy = file("policies/${var.iam_role_policy_filename}")
  role   = aws_iam_role.iam_role.id
}

resource "aws_iam_role_policy_attachment" "managed_policies" {
  count      = length(var.managed_policies)
  policy_arn = element(var.managed_policies, count.index)
  role       = aws_iam_role.iam_role.name
}

output "iam_role_output" {
  value = aws_iam_role.iam_role.name
}

output "iam_role_arn" {
  value = aws_iam_role.iam_role.arn
}