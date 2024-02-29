#Create a custom VPC
  resource "aws_vpc" "mern_vpc" {
    cidr_block = "10.0.0.0/16"
    tags = {
      "Name" = "mern_vpc"
    }
  }

#Create Public Subnet
  resource "aws_subnet" "public_subnet" {
    vpc_id                  = aws_vpc.mern_vpc.id
    cidr_block              = "10.0.1.0/24"
    availability_zone       = "ap-southeast-1a"
    map_public_ip_on_launch = true
    tags = {
      "Name" = "MERN-Public-subnet01"
    }
  }

  resource "aws_subnet" "public_subnet2" {
    vpc_id                  = aws_vpc.mern_vpc.id
    cidr_block              = "10.0.3.0/24"
    availability_zone       = "ap-southeast-1b"
    map_public_ip_on_launch = true
    tags = {
      "Name" = "MERN-Public-subnet02"
    }
  }
  

#Create Private Subnet
resource "aws_subnet" "private_subnet" {
  vpc_id            = aws_vpc.mern_vpc.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "ap-southeast-1a"

  tags = {
    "Name" = "MERN-Private-subnet01"
  }
}

  # Creating Internet Gateway IGW
  resource "aws_internet_gateway" "mern_igw" {
    vpc_id = aws_vpc.mern_vpc.id
    tags = {
      "Name" = "MERN-IGW"
    }
  }

  # Creating Route Table
  resource "aws_route_table" "mern_rt" {
    vpc_id = aws_vpc.mern_vpc.id
    tags = {
      "Name" = "MERN-Route-Table"
    }
  }

  # Create a Route in the Route Table with a route to IGW
  resource "aws_route" "mern_route" {
    route_table_id         = aws_route_table.mern_rt.id
    destination_cidr_block = "0.0.0.0/0"
    gateway_id             = aws_internet_gateway.mern_igw.id
  }

# Route table and subnet associations
resource "aws_route_table_association" "internet_access" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.mern_rt.id
}

# Create Elastic IP
resource "aws_eip" "main" {
  vpc              = true
}

# Create NAT Gateway
resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.main.id
  subnet_id     = aws_subnet.public_subnet.id

  tags = {
    Name = "NAT Gateway for Custom Kubernetes Cluster"
  }
}

# Add route to route table
resource "aws_route" "main" {
  route_table_id            = aws_vpc.mern_vpc.default_route_table_id
  destination_cidr_block    = "0.0.0.0/0"
  nat_gateway_id = aws_nat_gateway.main.id
}