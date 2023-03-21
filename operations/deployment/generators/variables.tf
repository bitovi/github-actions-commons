variable "aws_r53_enable_cert" {
  type        = string
  default     = "false"
}
variable "aws_ec2_instance_create" {
  type        = string
  default     = "false"
}
variable "aws_efs_create" {
  type        = string
  default     = "false"
}
variable "aws_elb_create" {
  type        = string
  default     = "false"
}
variable "env_aws_secret" {
  type        = string
  default     = ""
}
variable "aws_postgres_enable" {
  type        = string
  default     = "false"
}
variable "aws_r53_enable" {
  type        = string
  default     = "false"
}
variable "docker_install" {
  type        = string
  default     = "false"
}
variable "st2_install" {
  type        = string
  default     = "false"
}
