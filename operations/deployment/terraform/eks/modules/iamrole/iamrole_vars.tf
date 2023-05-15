variable "iam_role_name" {}
variable "iam_assume_role_filename" {}
variable "iam_role_policy_name" {}
variable "iam_role_policy_filename" {}
variable "managed_policies" {
    type = list
}
variable "common_tags" {
    type = map
    default = {}
}
