variable "ansible_skip" {
  type        = bool
  default     = "false"
}
variable "aws_r53_enable_cert" {
  type        = bool
  default     = "false"
}
variable "aws_ec2_instance_create" {
  type        = bool
  default     = "false"
}
variable "aws_ec2_instance_public_ip" {
  type        = bool
  default     = false
  description = "Attach public IP to the EC2 instance"
}
variable "aws_efs_create" {
  type        = bool
  default     = "false"
}
variable "aws_efs_create_ha" {
  type        = bool
  default     = "false"
}
variable "aws_efs_mount_id" {
  type        = string
  description = "ID of existing EFS"
  default     = ""
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
