resource "aws_vpc" "eks_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    "Name"        = "${var.eks_cluster_name}_vpc"
    "environment" = var.environment_tag
  }
}
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
resource "aws_internet_gateway" "eks_igw" {
  vpc_id = aws_vpc.eks_vpc.id
  tags = {
    "Name"        = "eks-IGW"
    "environment" = var.environment_tag
  }
}
resource "aws_eip" "main" {
  vpc = true
}

resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.main.id
  subnet_id     = aws_subnet.public_subnet[0].id

  tags = {
    Name        = "NAT Gateway for Custom Kubernetes Cluster"
    environment = var.environment_tag
  }
}
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.eks_vpc.id
  tags = {
    "Name"        = "${var.eks_cluster_name}-public-Route-Table"
    "environment" = var.environment_tag
  }
}
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.eks_vpc.id
  tags = {
    "Name"        = "${var.eks_cluster_name}-private-Route-Table"
    "environment" = var.environment_tag
  }
}
resource "aws_route" "public_route" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.eks_igw.id
}


resource "aws_route" "private_route" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_nat_gateway.main.id
}

resource "aws_route_table_association" "public_access" {
  count          = length(aws_subnet.public_subnet)
  subnet_id      = aws_subnet.public_subnet[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private_access" {
  count          = length(aws_subnet.private_subnet)
  subnet_id      = aws_subnet.private_subnet[count.index].id
  route_table_id = aws_route_table.private.id
}