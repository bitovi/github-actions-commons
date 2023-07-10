# All regions have "a", skipping az validation

data "aws_availability_zones" "all" {}

data "aws_subnet" "defaulta" {
  availability_zone = "${var.aws_region_current_name}a"
  default_for_az    = true
}
data "aws_subnet" "defaultb" {
  count             = contains(data.aws_availability_zones.all.names, "${var.aws_region_current_name}b") ? 1 : 0
  availability_zone = "${var.aws_region_current_name}b"
  default_for_az    = true
}
data "aws_subnet" "defaultc" {
  count             = contains(data.aws_availability_zones.all.names, "${var.aws_region_current_name}c") ? 1 : 0
  availability_zone = "${var.aws_region_current_name}c"
  default_for_az    = true
}
data "aws_subnet" "defaultd" {
  count             = contains(data.aws_availability_zones.all.names, "${var.aws_region_current_name}d") ? 1 : 0
  availability_zone = "${var.aws_region_current_name}d"
  default_for_az    = true
}
data "aws_subnet" "defaulte" {
  count             = contains(data.aws_availability_zones.all.names, "${var.aws_region_current_name}e") ? 1 : 0
  availability_zone = "${var.aws_region_current_name}e"
  default_for_az    = true
}
data "aws_subnet" "defaultf" {
  count             = contains(data.aws_availability_zones.all.names, "${var.aws_region_current_name}f") ? 1 : 0
  availability_zone = "${var.aws_region_current_name}f"
  default_for_az    = true
}

locals {
  aws_ec2_instance_type_offerings = sort(data.aws_ec2_instance_type_offerings.region_azs.locations)
  preferred_az = var.availability_zone != null ? var.availability_zone : local.aws_ec2_instance_type_offerings[random_integer.az_select[0].result]
}

data "aws_ec2_instance_type_offerings" "region_azs" {
  filter {
    name   = "instance-type"
    values = [var.aws_ec2_instance_type]
  }

  location_type = "availability-zone"
}

data "aws_subnet" "selected" {
  count             = contains(data.aws_availability_zones.all.names, local.preferred_az) ? 1 : 0
  availability_zone = local.preferred_az
  default_for_az    = true
}

resource "random_integer" "az_select" {
  count = length(data.aws_ec2_instance_type_offerings.region_azs.locations) > 0 ? 1 : 0
  
  min   = 0
  max   = length(data.aws_ec2_instance_type_offerings.region_azs.locations) - 1

  lifecycle {
    ignore_changes = all
  }
}

output "instance_type_available" {
  value       = length(data.aws_ec2_instance_type_offerings.region_azs.locations) > 0 ? "EC2 Instance type valid for this region" : "EC2 Instance type invalid for this region."
}