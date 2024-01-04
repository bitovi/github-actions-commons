#### VPC DEFAULT

data "aws_vpc" "default" {
  count   = var.aws_vpc_create ? 0 : var.aws_vpc_id != "" ? 0 : 1
  default = true
}

#### VPC IMPORT

data "aws_vpc" "exisiting" {
  count = var.aws_vpc_create ? 0 : var.aws_vpc_id != "" ? 1 : 0  
  id    = var.aws_vpc_id
}

#### VPC CREATE

resource "aws_vpc" "main" {
 count = var.aws_vpc_create ? 1 : 0
 cidr_block = var.aws_vpc_cidr_block
 enable_dns_hostnames = "true"
 tags = {
   Name = var.aws_vpc_name != "" ? var.aws_vpc_name : "VPC for ${var.aws_resource_identifier}"
 }
}

### Private

 resource "aws_subnet" "private" {
   count             = var.aws_vpc_create ? length(local.aws_vpc_private_subnets) : 0
   vpc_id            = aws_vpc.main[0].id
   cidr_block        = element(local.aws_vpc_private_subnets, count.index)
   availability_zone = element(local.aws_vpc_availability_zones, count.index)

   tags = merge({
     Name = "${var.aws_resource_identifier}-private${count.index + 1}"
     Tier = "Private"
   },
   var.aws_eks_create ? local.private_subnet_tags : {})
}

resource "aws_route_table" "private" {
  #count  = var.aws_vpc_create ? length(local.aws_vpc_private_subnets) : 0
  count  = var.aws_vpc_create ? 1 : 0
  vpc_id = aws_vpc.main[0].id
  tags = {
    Name        = "${var.aws_resource_identifier}-private"
  }
  depends_on = [ aws_vpc.main ]
}

resource "aws_route_table_association" "private" {
  count          = var.aws_vpc_create ? length(local.aws_vpc_private_subnets) : 0
  subnet_id      = element(aws_subnet.private.*.id, count.index)
  route_table_id = aws_route_table.private[0].id
}

### Public

resource "aws_subnet" "public" {
  count                   = var.aws_vpc_create ? length(local.aws_vpc_public_subnets) : 0
  vpc_id                  = aws_vpc.main[0].id
  cidr_block              = element(local.aws_vpc_public_subnets, count.index)
  availability_zone       = element(local.aws_vpc_availability_zones, count.index)
  map_public_ip_on_launch = true

  tags = merge({
    Name = "${var.aws_resource_identifier}-public${count.index + 1}"
    Tier = "Public"
  },
  var.aws_eks_create ? local.public_subnet_tags : {})
  depends_on = [ aws_vpc.main ]
}

resource "aws_route_table" "public" {
  count  = var.aws_vpc_create ? 1 : 0
  vpc_id = aws_vpc.main[0].id

  tags = {
    Name        = "${var.aws_resource_identifier}-public"
  }  
  depends_on = [ aws_vpc.main ]
}

resource "aws_route_table_association" "public" {
  count          = var.aws_vpc_create ? length(local.aws_vpc_public_subnets) : 0
  subnet_id      = element(aws_subnet.public.*.id, count.index)
  route_table_id = aws_route_table.public[0].id
}

resource "aws_internet_gateway" "gw" {
  count  = var.aws_vpc_create ? 0 : 0 # testing igw
  vpc_id = aws_vpc.main[0].id
  depends_on = [ aws_vpc.main ]
}

resource "aws_route" "public" {
  count                  = 0 #var.aws_vpc_create ? length(aws_route_table.public) : 0
  route_table_id         = aws_route_table.public[0].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.gw[0].id
}

# NAT Gateway
locals {
  nat_gateway_count           = var.aws_vpc_single_nat_gateway ? 1 : length(local.aws_vpc_availability_zones)
  nat_gateway_ips             = local.aws_vpc_reuse_nat_ips ? local.aws_vpc_external_nat_ip_ids : try(aws_eip.nat[*].id, [])
  aws_vpc_reuse_nat_ips       = var.aws_vpc_external_nat_ip_ids != "" ? true : false
  aws_vpc_external_nat_ip_ids = var.aws_vpc_external_nat_ip_ids != "" ? [for n in split(",", var.aws_vpc_external_nat_ip_ids) : (n)] : []
  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
  }
  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1 
  }
}

# NAT Gateway in the public subnet
resource "aws_nat_gateway" "nat_gw" {
  count = var.aws_vpc_enable_nat_gateway && var.aws_vpc_create ? local.nat_gateway_count : 0

  allocation_id = element(
    local.nat_gateway_ips,
    var.aws_vpc_single_nat_gateway ? 0 : count.index,
  )
  subnet_id = element(
    aws_subnet.public[*].id,
    var.aws_vpc_single_nat_gateway ? 0 : count.index,
  )

  tags = merge(
    {
      "Name" = format(
        "${var.aws_resource_identifier}-%s",
        element(local.aws_vpc_availability_zones, var.aws_vpc_single_nat_gateway ? 0 : count.index),
      )
    }
  )

 # depends_on = [aws_internet_gateway.gw]
}

resource "aws_route" "private_nat_gateway" {
  count = var.aws_vpc_enable_nat_gateway && var.aws_vpc_create ? local.nat_gateway_count : 0

  route_table_id         = aws_route_table.private[0].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = element(aws_nat_gateway.nat_gw[*].id, count.index)

  timeouts {
    create = "5m"
  }
}

resource "aws_eip" "nat" {
  count = var.aws_vpc_enable_nat_gateway && !local.aws_vpc_reuse_nat_ips && var.aws_vpc_create ? local.nat_gateway_count : 0

  domain = "vpc"

  tags = merge(
    {
      "Name" = format(
        "${var.aws_resource_identifier}-%s",
        element(local.aws_vpc_availability_zones, var.aws_vpc_single_nat_gateway ? 0 : count.index),
      )
    }
  )
 # depends_on = [aws_internet_gateway.gw]
}


### Data source

locals {
  aws_vpc_public_subnets     = var.aws_vpc_public_subnets != "" ? [for n in split(",", var.aws_vpc_public_subnets) : (n)] : []
  aws_vpc_private_subnets    = var.aws_vpc_private_subnets != "" ? [for n in split(",", var.aws_vpc_private_subnets) : (n)] : []
  aws_vpc_availability_zones = var.aws_vpc_availability_zones != "" ? [for n in split(",", var.aws_vpc_availability_zones) : (n)] : local.reordered_availability_zones # data.aws_availability_zones.all.names
  selected_vpc_id            = var.aws_vpc_create ? aws_vpc.main[0].id : var.aws_vpc_id != "" ? var.aws_vpc_id : data.aws_vpc.default[0].id
}

# Get the VPC details
data "aws_vpc" "selected" {
  id    = local.selected_vpc_id
}

# Sort the AZ list, and ensure that the az from the existing EC2 instance is first in the list

locals {
  sorted_availability_zones = sort(data.aws_availability_zones.all.names)
  index_of_existing_az      = index(local.sorted_availability_zones, local.aws_ec2_zone_selected)
  
  before_existing_az = local.index_of_existing_az == 0 ? [] : slice(local.sorted_availability_zones, 0, local.index_of_existing_az)
  after_existing_az  = local.index_of_existing_az == length(local.sorted_availability_zones) -1 ? [] : slice(local.sorted_availability_zones, local.index_of_existing_az + 1, length(local.sorted_availability_zones))
  
  reordered_availability_zones = concat(
    [element(local.sorted_availability_zones, local.index_of_existing_az)],
    local.before_existing_az,
    local.after_existing_az
  )
}

### Outputs

output "aws_selected_vpc_id" {
  description = "The subnet ids from the default vpc"
  value       = var.aws_vpc_create ? aws_vpc.main[0].id : var.aws_vpc_id != "" ? var.aws_vpc_id : data.aws_vpc.default[0].id
}

output "aws_selected_vpc_subnets" {
  description = "The subnet ids from the default vpc"
  value       = data.aws_subnets.vpc_subnets.ids
}

output "aws_vpc_subnet_selected" {
  value = local.use_default ? data.aws_subnet.default_selected[0].id : data.aws_subnet.selected[0].id
}

output "aws_region_current_name" {
  description = "Current region name"
  value = data.aws_region.current.name
}

output "aws_vpc_cidr_block" {
  description = "CIDR block of chosen VPC"
  value = data.aws_vpc.selected.cidr_block
}

output "aws_vpc_dns_enabled" {
  description = "Boolean of DNS enabled in VPC"
  value = data.aws_vpc.selected.enable_dns_hostnames
}