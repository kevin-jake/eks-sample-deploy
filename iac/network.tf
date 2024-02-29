#Create a custom VPC
resource "aws_vpc" "eks_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    "Name"        = "${var.eks_cluster_name}_vpc"
    "environment" = var.environment_tag
  }
}

#Create Public Subnet
resource "aws_subnet" "public_subnet" {
  count                   = length(var.availability_zones)
  vpc_id                  = aws_vpc.eks_vpc.id
  cidr_block              = element(var.public_subnet_cidr_blocks, count.index)
  availability_zone       = element(var.availability_zones, count.index)
  map_public_ip_on_launch = true
  tags = {
    Name        = "${var.eks_cluster_name}-public-subnet-${element(var.availability_zones, count.index)}"
    environment = var.environment_tag
  }
}

resource "aws_subnet" "private_subnet" {
  count             = length(var.availability_zones)
  vpc_id            = aws_vpc.eks_vpc.id
  cidr_block        = element(var.private_subnet_cidr_blocks, count.index)
  availability_zone = element(var.availability_zones, count.index)

  tags = {
    Name        = "${var.eks_cluster_name}-private-subnet-${element(var.availability_zones, count.index)}"
    environment = var.environment_tag
  }
}

# Creating Internet Gateway IGW
resource "aws_internet_gateway" "eks_igw" {
  vpc_id = aws_vpc.eks_vpc.id
  tags = {
    "Name"        = "eks-IGW"
    "environment" = var.environment_tag
  }
}

# Creating Route Table
resource "aws_route_table" "eks_rt" {
  vpc_id = aws_vpc.eks_vpc.id
  tags = {
    "Name"        = "${var.eks_cluster_name}-Route-Table"
    "environment" = var.environment_tag
  }
}

# Create a Route in the Route Table with a route to IGW
resource "aws_route" "eks_route" {
  route_table_id         = aws_route_table.eks_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.eks_igw.id
}

# Route table and subnet associations
resource "aws_route_table_association" "internet_access" {
  count          = length(aws_subnet.public_subnet)
  subnet_id      = aws_subnet.public_subnet[count.index].id
  route_table_id = aws_route_table.eks_rt.id
}

# Create Elastic IP
resource "aws_eip" "main" {
  vpc = true
}

# Create NAT Gateway
resource "aws_nat_gateway" "main" {
  count         = length(aws_subnet.public_subnet)
  allocation_id = aws_eip.main.id
  subnet_id     = aws_subnet.public_subnet[count.index].id

  tags = {
    Name = "NAT Gateway for Custom Kubernetes Cluster"
  }
}

# Add route to route table
resource "aws_route" "main" {
  count                  = length(aws_subnet.public_subnet)
  route_table_id         = aws_vpc.eks_vpc.default_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.main[count.index].id
}