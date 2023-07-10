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

# Dupe from EC2, but needed to avoid passing a bunch of vars
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

### 
locals {
  # no_zone_mapping: Creates a empty zone mapping object list
  no_zone_mapping  = { "" : { "subnet_id" : "", "security_groups" : [""] } }
  # ec2_zone_mapping: Creates a zone mapping object list based on default values (default sg, default subnet, etc)
  ec2_zone_mapping = { "${local.preferred_az}" : { "subnet_id" : "${data.aws_subnet.selected[0].id}", "security_groups" : [var.aws_security_group_ec2_sg_name] } }

  # auto_ha_availability_zone*: Creates zone map objects for each available AZ in a region
  auto_ha_availability_zonea = {
    "${var.aws_region_current_name}a" : {
      "subnet_id" : data.aws_subnet.defaulta.id,
      "security_groups" : [var.aws_security_group_default_id]
  } }
  auto_ha_availability_zoneb = length(data.aws_subnet.defaultb) > 0 ? ({
    "${var.aws_region_current_name}b" : {
      "subnet_id" : data.aws_subnet.defaultb[0].id,
      "security_groups" : [var.aws_security_group_default_id]
    }
  }) : null
  auto_ha_availability_zonec = length(data.aws_subnet.defaultc) > 0 ? ({
    "${var.aws_region_current_name}c" : {
      "subnet_id" : data.aws_subnet.defaultc[0].id,
      "security_groups" : [var.aws_security_group_default_id]
    }
  }) : null
  auto_ha_availability_zoned = length(data.aws_subnet.defaultd) > 0 ? ({
    "${var.aws_region_current_name}d" : {
      "subnet_id" : data.aws_subnet.defaultd[0].id,
      "security_groups" : [var.aws_security_group_default_id]
    }
  }) : null
  auto_ha_availability_zonee = length(data.aws_subnet.defaulte) > 0 ? ({
    "${var.aws_region_current_name}e" : {
      "subnet_id" : data.aws_subnet.defaulte[0].id,
      "security_groups" : [var.aws_security_group_default_id]
    }
  }) : null
  auto_ha_availability_zonef = length(data.aws_subnet.defaultf) > 0 ? ({
    "${var.aws_region_current_name}f" : {
      "subnet_id" : data.aws_subnet.defaultf[0].id,
      "security_groups" : [var.aws_security_group_default_id]
    }
  }) : null
  # ha_zone_mapping: Creates a zone mapping object list for all available AZs in a region
  ha_zone_mapping = merge(local.auto_ha_availability_zonea, local.auto_ha_availability_zoneb, local.auto_ha_availability_zonec, local.auto_ha_availability_zoned, local.auto_ha_availability_zonee, local.auto_ha_availability_zonef)
}

output "ha_zone_mapping" {
  value = local.ha_zone_mapping
}