locals {
  # replica_destination: Checks whether a replica destination exists otherwise sets a default
  replica_destination = var.aws_efs_replication_destination != "" ? var.aws_efs_replication_destination : data.aws_region.current.name
  create_efs          = var.aws_efs_create ? true : (var.aws_efs_create_ha ? true : false)
}

# ---------------------CREATE--------------------------- #
resource "aws_efs_file_system" "efs" {
  count = local.create_efs ? 1 : 0
  # File system
  creation_token = "${var.aws_resource_identifier}-token-modular"
  encrypted      = true

  lifecycle_policy {
    transition_to_ia = var.aws_efs_transition_to_inactive
  }

  tags = {
    Name = "${var.aws_resource_identifier}-efs-modular"
  }
}

data "aws_efs_file_system" "efs" {
  file_system_id = local.create_efs ? aws_efs_file_system.efs[0].id : var.aws_efs_fs_id
}

resource "aws_efs_backup_policy" "efs_policy" {
  count          = local.create_efs && var.aws_efs_enable_backup_policy ? 1 : 0
  file_system_id = data.aws_efs_file_system.efs.id

  backup_policy {
    status = "ENABLED"
  }
}

resource "aws_efs_replication_configuration" "efs_rep_config" {
  count                 = local.create_efs && var.aws_efs_create_replica ? 1 : 0
  source_file_system_id = data.aws_efs_file_system.efs.id

  destination {
    region = local.replica_destination
  }
}

#### Defined EFS - Set up directly through the action
resource "aws_security_group" "efs_security_group_defined" { # Incoming from EFS value
  count       = local.incoming_set ? 1 : 0
  name        = var.aws_efs_security_group_name != "" ? var.aws_efs_security_group_name : "SG for ${var.aws_resource_identifier} - EFS - Defined"
  description = "SG for ${var.aws_resource_identifier} - EFS - Defined"
  vpc_id      = local.incoming_vpc
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "${var.aws_resource_identifier}-efs-sg-def"
  }
}

resource "aws_security_group_rule" "efs_nfs_incoming_ports_defined" { # Incoming from EFS value
  count             = local.incoming_set ? 1 : 0
  type              = "ingress"
  description       = "NFS from VPC"
  from_port         = 2049
  to_port           = 2049
  protocol          = "tcp"
  cidr_blocks       = [data.aws_vpc.incoming[0].cidr_block]
  security_group_id = aws_security_group.efs_security_group_defined[0].id
  depends_on        = [ aws_security_group.efs_security_group_defined ]
}

resource "aws_efs_mount_target" "efs_mount_target_incoming" {
  count           = length(local.incoming_subnets)
  file_system_id  = data.aws_efs_file_system.efs.id
  subnet_id       = local.incoming_subnets[count.index]
  security_groups = [aws_security_group.efs_security_group_defined[0].id]
}
####

#### Action SG. Rules and Mount
resource "aws_security_group" "efs_security_group_action" {
  count       = local.defined ? 1 : 0
  name        = var.aws_efs_security_group_name != "" ? var.aws_efs_security_group_name : "SG for ${var.aws_resource_identifier} - EFS - Action defined"
  description = "SG for ${var.aws_resource_identifier} - EFS - Action defined"
  vpc_id      = var.aws_selected_vpc_id
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "${var.aws_resource_identifier}-efs-sg-act"
  }
}


resource "aws_security_group_rule" "efs_nfs_incoming_ports_action" { # Selected from VPC Module
  count             = local.defined_set ? 1 : 0
  type              = "ingress"
  description       = "NFS from VPC"
  from_port         = 2049
  to_port           = 2049
  protocol          = "tcp"
  cidr_blocks       = [data.aws_vpc.selected[0].cidr_block]
  security_group_id = aws_security_group.efs_security_group_action[0].id
  depends_on        = [ aws_security_group.efs_security_group_action ]
}

resource "aws_efs_mount_target" "efs_mount_target_action" {
  count           = length(local.module_subnets)
  file_system_id  = data.aws_efs_file_system.efs.id
  subnet_id       = local.module_subnets[count.index]
  security_groups = [aws_security_group.efs_security_group_action[0].id]
}

######


# Data sources from selected (Coming from VPC module)

data "aws_subnets" "selected_vpc_id"  {
  #for_each = var.aws_selected_vpc_id != null ? toset(data.aws_availability_zones.all.zone_ids) : []
  count = var.aws_selected_vpc_id != null ? length(var.aws_selected_az_list) : 0
  filter {
    name   = "vpc-id"
    values = [var.aws_selected_vpc_id]
  }
  filter {
    name   = "availability-zone-id"
    values = [var.aws_selected_az_list[count.index]]
    #values = ["${each.value}"]
  }
}

data "aws_vpc" "selected" {
  count = var.aws_selected_vpc_id != null ? 1 : 0
  id    = var.aws_selected_vpc_id
}

# Data sources from EFS inputs

data "aws_subnets" "incoming_vpc" {
  #for_each = local.incoming_set ? toset(data.aws_availability_zones.all.zone_ids) : []
  count = local.incoming_set ? length(var.aws_selected_az_list) : 0
  filter {
    name   = "vpc-id"
    values = [local.incoming_vpc] 
  }
  filter {
    name   = "availability-zone-id"
    values = [var.aws_selected_az_list[count.index]]
    #values = ["${each.value}"]
  }
}

data "aws_vpc" "incoming" {
  count = local.incoming_set ? 1 : 0
  id    = local.incoming_vpc
}

data "aws_subnet" "incoming" {
  count = var.aws_efs_subnet_ids != null ? 1 : 0
  id = local.aws_efs_subnet_ids[0]
}

##### 

## Now to get the details of VPCs and subnets

# If no HA, and don't have the subnet id, will look up in the action defined zone, filtering the VPC. If none, or more than one, it will fail.
data "aws_subnet" "no_ha" {
  count  = var.aws_efs_create_ha ? 0 : local.incoming_vpc != null && var.aws_efs_subnet_ids == null ? 1 : 0
  filter {
    name   = "vpc-id"
    values = [local.incoming_vpc]
  }
  availability_zone = var.aws_selected_az
}

# If one or more subnets, will grab the first one to get the VPC ID of it. 
data "aws_subnet" "incoming_subnet" {
  count = var.aws_efs_subnet_ids != null ? 1 : 0
  id = local.aws_efs_subnet_ids[0]
}

# Needed for security group - Need to get the VPC CIDR Block


####

data "aws_region" "current" {}

#data "aws_availability_zones" "all" {
#  filter {
#    name   = "region-name"
#    values = [data.aws_region.current.name]
#  }
#}



locals {
  ### Incoming definitions, need a VPC or a Subnet, if nothing, false
  incoming_set = var.aws_efs_vpc_id != null || var.aws_efs_subnet_ids != null ? true : false
  #defined_set  = var.aws_selected_vpc_id != null || var.aws_selected_subnet_id != null ? true : false
  defined_set = true # It will always be true. If not creating a VPC, will use am existing one or the default one.
  # Convert incoming subnets to list
  aws_efs_subnet_ids = var.aws_efs_subnet_ids != null ? [for n in split(",", var.aws_efs_subnet_ids) : (n)] : []
  ### 
  
  # Define the incoming VPC ID - Will try with the defined var, if not, will try to get it from the subnet. 
  incoming_vpc = var.aws_efs_vpc_id != null ? var.aws_efs_vpc_id : var.aws_efs_subnet_ids != null ? data.aws_subnet.incoming_subnet[0].vpc_id : null
  # Make a list with the subnets defined in the action - From the VPC
  incoming_vpc_ids = compact([for k, v in data.aws_subnets.incoming_vpc : try((v.ids[0]),null)])
  incoming_subnets_from_vpc = var.aws_efs_create_ha ? local.incoming_vpc_ids : try([data.aws_subnet.no_ha[0].id],[]) # One or all subnets.
  #incoming_subnets_from_vpc = var.aws_efs_create_ha ? try(data.aws_subnets.incoming_vpc[0].ids,[]) : try([data.aws_subnet.no_ha[0].id],[]) # One or all subnets.
  # If subnet was provided, use that as a list, if not, grab the one from the VPC. Will bring only one if no HA, or the whole set.
  incoming_subnets = var.aws_efs_subnet_ids != null ? local.aws_efs_subnet_ids : local.incoming_subnets_from_vpc

  # Get the subnets 
  module_vpc_ids = compact([for k, v in data.aws_subnets.selected_vpc_id : try((v.ids[0]),null)])
  module_subnets = var.aws_efs_create_ha ? local.module_vpc_ids : try([var.aws_selected_subnet_id],[])
  #module_subnets = var.aws_efs_create_ha ? try(data.aws_subnets.selected_vpc_id[0].ids,[]) : try([var.aws_selected_subnet_id],[])
}

output "aws_efs_fs_id" {
  value = data.aws_efs_file_system.efs.id
}