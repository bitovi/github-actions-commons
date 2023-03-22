variable "aws_r53_enable_cert" {
  type        = bool
  default     = "false"
}
variable "aws_ec2_instance_create" {
  type        = bool
  default     = "false"
}
variable "aws_efs_create" {
  type        = bool
  default     = "false"
}
variable "aws_elb_create" {
  type        = bool
  default     = "false"
}
variable "env_aws_secret" {
  type        = string
  default     = ""
}
variable "aws_postgres_enable" {
  type        = bool
  default     = "false"
}
variable "aws_r53_enable" {
  type        = bool
  default     = "false"
}
variable "docker_install" {
  type        = bool
  default     = "false"
}
variable "st2_install" {
  type        = bool
  default     = "false"
}
