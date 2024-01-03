# All regions have "a", skipping az validation

data "aws_region" "current" {}

data "aws_availability_zones" "all" {
  filter {
    name   = "region-name"
    values = [data.aws_region.current.name]
  }  
  state = "available"
}

data "aws_subnets" "vpc_subnets" {
  filter {
    name   = "vpc-id"
    values = [local.selected_vpc_id]
  }
}

data "aws_subnet" "defaulta" {
  count             = contains(data.aws_availability_zones.all.names, "${data.aws_region.current.name}a") && local.use_default ? 1 : 0
  availability_zone = "${data.aws_region.current.name}a"
  default_for_az    = true
}
data "aws_subnet" "defaultb" {
  count             = contains(data.aws_availability_zones.all.names, "${data.aws_region.current.name}b") && local.use_default ? 1 : 0
  availability_zone = "${data.aws_region.current.name}b"
  default_for_az    = true
}
data "aws_subnet" "defaultc" {
  count             = contains(data.aws_availability_zones.all.names, "${data.aws_region.current.name}c") && local.use_default ? 1 : 0
  availability_zone = "${data.aws_region.current.name}c"
  default_for_az    = true
}
data "aws_subnet" "defaultd" {
  count             = contains(data.aws_availability_zones.all.names, "${data.aws_region.current.name}d") && local.use_default ? 1 : 0
  availability_zone = "${data.aws_region.current.name}d"
  default_for_az    = true
}
data "aws_subnet" "defaulte" {
  count             = contains(data.aws_availability_zones.all.names, "${data.aws_region.current.name}e") && local.use_default ? 1 : 0
  availability_zone = "${data.aws_region.current.name}e"
  default_for_az    = true
}
data "aws_subnet" "defaultf" {
  count             = contains(data.aws_availability_zones.all.names, "${data.aws_region.current.name}f") && local.use_default ? 1 : 0
  availability_zone = "${data.aws_region.current.name}f"
  default_for_az    = true
}

locals {
  use_default = var.aws_vpc_create ? false : var.aws_vpc_id != "" ? false : true
  aws_ec2_instance_type_offerings = sort(data.aws_ec2_instance_type_offerings.region_azs.locations)
  aws_ec2_zone_selected = local.aws_ec2_instance_type_offerings[random_integer.az_select[0].result]
  preferred_az = var.aws_vpc_availability_zones != "" ? local.aws_vpc_availability_zones[0] : var.aws_vpc_id != "" ? data.aws_subnet.selected[0].availability_zone : local.aws_ec2_zone_selected
  #preferred_az = var.aws_vpc_availability_zones != "" ? local.aws_ec2_zone_selected : var.aws_vpc_id != "" ? data.aws_subnet.selected[0].availability_zone : local.aws_ec2_zone_selected
}

data "aws_ec2_instance_type_offerings" "region_azs" {
  filter {
    name   = "instance-type"
    values = [var.aws_ec2_instance_type]
  }
  location_type = "availability-zone"
}


resource "random_integer" "az_select" {
  count = length(data.aws_ec2_instance_type_offerings.region_azs.locations) > 0 ? 1 : 0
  
  min   = 0
  max   = length(data.aws_ec2_instance_type_offerings.region_azs.locations) - 1

  lifecycle {
    ignore_changes = all
  }
}

data "aws_subnet" "default_selected" {
  count             = local.use_default ? contains(data.aws_availability_zones.all.names, local.preferred_az) ? 1 : 0 : 0
  availability_zone = local.preferred_az
  default_for_az    = true #-  What happens if I have multiple subnets in the same az?
}

data "aws_subnet" "selected" {
  count = local.use_default ? 0 : 1
  id    = var.aws_vpc_subnet_id != "" ? var.aws_vpc_subnet_id : var.aws_vpc_create ? aws_subnet.public[0].id : data.aws_subnets.vpc_subnets.ids[0]
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

### 
locals {
  aws_ec2_security_group_name = var.aws_ec2_security_group_name != "" ? var.aws_ec2_security_group_name : "SG for ${var.aws_resource_identifier} - EC2"
  # auto_ha_availability_zone*: Creates zone map objects for each available AZ in a region
  auto_ha_availability_zonea = length(data.aws_subnet.defaultb) > 0 ? ({
    "${data.aws_region.current.name}a" : {
      "subnet_id" : data.aws_subnet.defaulta[0].id,
      "security_groups" : [data.aws_security_group.default.id]
    }
  }) : null
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
  chosen_subnet_id = try(data.aws_subnet.default_selected[0].id,data.aws_subnets.vpc_subnets.ids[0],aws_subnet.public[0].id)
  # ha_zone_mapping: Creates a zone mapping object list for all available AZs in a region
  ha_zone_mapping = merge(local.auto_ha_availability_zonea, local.auto_ha_availability_zoneb, local.auto_ha_availability_zonec, local.auto_ha_availability_zoned, local.auto_ha_availability_zonee, local.auto_ha_availability_zonef)
  ec2_zone_mapping =  { "${local.preferred_az}" : { "subnet_id" : "${local.chosen_subnet_id}", "security_groups" : ["${local.aws_ec2_security_group_name}"] } }
}

output "aws_security_group_default_id" {
  description = "The AWS Default SG Id"
  value       = data.aws_security_group.default.id
}

output "instance_type_available" {
  value       = length(data.aws_ec2_instance_type_offerings.region_azs.locations) > 0 ? "EC2 Instance type valid for this region" : "EC2 Instance type invalid for this region."
}

output "ha_zone_mapping" {
  value = local.ha_zone_mapping
}

output "ec2_zone_mapping" {
  value = local.ec2_zone_mapping
}

output "preferred_az" {
  value = local.preferred_az
}

output "aws_subnets" {
  value = data.aws_subnets.vpc_subnets
}

output "availability_zones" {
  value = data.aws_availability_zones.all.zone_ids
}