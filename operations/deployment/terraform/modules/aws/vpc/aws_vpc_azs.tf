# All regions have "a", skipping az validation

data "aws_availability_zones" "all" {}

data "aws_region" "current" {}

data "aws_subnets" "vpc_subnets" {
  filter {
    name   = "vpc-id"
    values = [local.selected_vpc_id]
  }
}

data "aws_subnet" "defaulta" {
  availability_zone = "${data.aws_region.current.name}a"
  vpc_id = local.selected_vpc_id
}
data "aws_subnet" "defaultb" {
  count             = contains(data.aws_availability_zones.all.names, "${data.aws_region.current.name}b") ? 1 : 0
  availability_zone = "${data.aws_region.current.name}b"
  vpc_id = local.selected_vpc_id
}
data "aws_subnet" "defaultc" {
  count             = contains(data.aws_availability_zones.all.names, "${data.aws_region.current.name}c") ? 1 : 0
  availability_zone = "${data.aws_region.current.name}c"
  vpc_id = local.selected_vpc_id
}
data "aws_subnet" "defaultd" {
  count             = contains(data.aws_availability_zones.all.names, "${data.aws_region.current.name}d") ? 1 : 0
  availability_zone = "${data.aws_region.current.name}d"
  vpc_id = local.selected_vpc_id
}
data "aws_subnet" "defaulte" {
  count             = contains(data.aws_availability_zones.all.names, "${data.aws_region.current.name}e") ? 1 : 0
  availability_zone = "${data.aws_region.current.name}e"
  vpc_id = local.selected_vpc_id
}
data "aws_subnet" "defaultf" {
  count             = contains(data.aws_availability_zones.all.names, "${data.aws_region.current.name}f") ? 1 : 0
  availability_zone = "${data.aws_region.current.name}f"
  vpc_id = local.selected_vpc_id
}

locals {
  aws_ec2_instance_type_offerings = sort(data.aws_ec2_instance_type_offerings.region_azs.locations)
  preferred_az = var.availability_zone != null ? var.availability_zone : local.aws_ec2_instance_type_offerings[random_integer.az_select[0].result]
}

data "aws_ec2_instance_type_offerings" "region_azs" {
  filter {
    name   = "instance-type"
    values = [var.aws_ec2_instance_type] ## Change this to AWS Region ID
  }
  location_type = "availability-zone"
}

data "aws_subnet" "selected" {
  count             = contains(data.aws_availability_zones.all.names, local.preferred_az) ? 1 : 0
  availability_zone = local.preferred_az
  #default_for_az    = true
}

output "aws_vpc_subnet_selected" {
  value = data.aws_subnet.selected.id
}

data "aws_security_group" "default" {
  filter {
    name   = "group-name"
    values = ["default"]
  }
  filter {
    name   = "vpc-id"
    values = [local.selected_vpc_id]
  }
}

output "aws_security_group_default_id" {
  description = "The AWS Default SG Id"
  value       = data.aws_security_group.default.id
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
  ec2_zone_mapping =  { "${local.preferred_az}" : { "subnet_id" : "${data.aws_subnet.selected[0].id}", "security_groups" : var.aws_ec2_securitu_group_name } }

  # auto_ha_availability_zone*: Creates zone map objects for each available AZ in a region
  auto_ha_availability_zonea = {
    "${data.aws_region.current.name}a" : {
      "subnet_id" : data.aws_subnet.defaulta.id,
      "security_groups" : [data.aws_security_group.default.id]
  } }
  auto_ha_availability_zoneb = length(data.aws_subnet.defaultb) > 0 ? ({
    "${data.aws_region.current.name}b" : {
      "subnet_id" : data.aws_subnet.defaultb[0].id,
      "security_groups" : [data.aws_security_group.default.id]
    }
  }) : null
  auto_ha_availability_zonec = length(data.aws_subnet.defaultc) > 0 ? ({
    "${data.aws_region.current.name}c" : {
      "subnet_id" : data.aws_subnet.defaultc[0].id,
      "security_groups" : [data.aws_security_group.default.id]
    }
  }) : null
  auto_ha_availability_zoned = length(data.aws_subnet.defaultd) > 0 ? ({
    "${data.aws_region.current.name}d" : {
      "subnet_id" : data.aws_subnet.defaultd[0].id,
      "security_groups" : [data.aws_security_group.default.id]
    }
  }) : null
  auto_ha_availability_zonee = length(data.aws_subnet.defaulte) > 0 ? ({
    "${data.aws_region.current.name}e" : {
      "subnet_id" : data.aws_subnet.defaulte[0].id,
      "security_groups" : [data.aws_security_group.default.id]
    }
  }) : null
  auto_ha_availability_zonef = length(data.aws_subnet.defaultf) > 0 ? ({
    "${data.aws_region.current.name}f" : {
      "subnet_id" : data.aws_subnet.defaultf[0].id,
      "security_groups" : [data.aws_security_group.default.id]
    }
  }) : null
  # ha_zone_mapping: Creates a zone mapping object list for all available AZs in a region
  ha_zone_mapping = merge(local.auto_ha_availability_zonea, local.auto_ha_availability_zoneb, local.auto_ha_availability_zonec, local.auto_ha_availability_zoned, local.auto_ha_availability_zonee, local.auto_ha_availability_zonef)
}

#output "ec2_zone_mapping" {
#  value = local.ec2_zone_mapping
#}

#output "ha_zone_mapping" {
#  value = local.ha_zone_mapping
#}