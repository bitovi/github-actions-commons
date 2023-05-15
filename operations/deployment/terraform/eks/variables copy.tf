variable "aws-profile" {
  description = "enter the aws profile name"
  type        = string
  default = "default"
}

variable "aws-region" {
  description = "aws region name"
  type        = string
  default = "us-east-1"
}

variable "environment" {
  description = "environment name"
  type        = string
  default = "test"
}

variable "stackname" {
  description = "enter the stack name"
  type        = string
  default = "eks-test"
}

variable "account_id" {
  description = "enter the stack name"
  type        = number
}

variable "cidr_block" {
  type        = string
  description = "Base CIDR block which is divided into subnet CIDR blocks (e.g. `10.0.0.0/16`)"
  default = "10.0.0.0/16"
}

variable "workstation_cidr" {
  type        = list(string)
  description = "your local workstation public IP"
  default = ["17.168.95.114/32"]
}

variable "availability_zones" {
  type        = list(string)
  description = "List of Availability Zones (e.g. `['us-east-1a', 'us-east-1b', 'us-east-1c']`)"
  default = ["us-east-1a", "us-east-1b"]
}

variable "private_subnets" {
  type        = list(string)
  description = "List of private subnets (e.g. `['10.0.1.0/24', '10.0.2.0/24']`)"
  default = [ "10.0.1.0/24","10.0.2.0/24" ]
}

variable "public_subnets" {
  type        = list(string)
  description = "List of public subnets (e.g. `['10.0.101.0/24', '10.0.102.0/24']`)"
  default = [ "10.0.101.0/24","10.0.102.0/24" ]
}

variable "cluster_version" {
  description = "enter the kubernetes version"
  type        = number
  default = "1.26"
}

variable "image_id" {
  description = "enter the aws ami related to kubernetes version"
  type        = string
  default = "ami-0b0d79012c6bfa493"
}

variable "instance_type" {
  description = "enter the aws instance type"
  type        = string
  default = "t3a.medium"
}


variable "ec2_key_pair" {
  description = "Enter the existing ec2 key pair for worker nodes"
  type        = string
}

variable "desired_capacity" {
  description = "Enter the desired capacity for the worker nodes"
  type        = number
  default     = "2"
}

variable "max_size" {
  description = "Enter the max_size for the worker nodes"
  type        = number
  default     = "4"
}

variable "min_size" {
  description = "Enter the min_size for the worker nodes"
  type        = number
  default     = "2"
}
