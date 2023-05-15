variable "iam_instance_profile_name" {}
variable "iam_role_name" {}
variable "iaminstprofile_depends_on" {
  type    = any
  default = null
}
variable "common_tags" {
    type = map
    default = {}
}