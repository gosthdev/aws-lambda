resource "aws_vpc" "main_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true  
  enable_dns_hostnames = true 
  tags = {
    Name = "${local.name_prefix}-vpc"
  }
}

resource "aws_subnet" "private_subnet_a" {
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = var.private_subnet_a_cidr
  availability_zone = var.availability_zone_a
  tags = {
    Name = "${local.name_prefix}-private-a"
  }
}

resource "aws_subnet" "private_subnet_b" {
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = var.private_subnet_b_cidr
  availability_zone = var.availability_zone_b
  tags = {
    Name = "${local.name_prefix}-private-b"
  }
}

resource "aws_route_table" "private_rt_a" {
  vpc_id = aws_vpc.main_vpc.id
  tags = {
    Name = "${local.name_prefix}-private-rt-a"
  }
}

resource "aws_route_table" "private_rt_b" {
  vpc_id = aws_vpc.main_vpc.id
  tags = {
    Name = "${local.name_prefix}-private-rt-b"
  }
}

resource "aws_route_table_association" "private_rt_a" {
  subnet_id      = aws_subnet.private_subnet_a.id
  route_table_id = aws_route_table.private_rt_a.id
}

resource "aws_route_table_association" "private_rt_b" {
  subnet_id      = aws_subnet.private_subnet_b.id
  route_table_id = aws_route_table.private_rt_b.id
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main_vpc.id

  tags = {
    Name = "${local.name_prefix}-igw"
  }
}

resource "aws_subnet" "public_subnet_a" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = var.public_subnet_a_cidr
  availability_zone       = var.availability_zone_a
  map_public_ip_on_launch = true

  tags = {
    Name = "${local.name_prefix}-public-a"
  }
}

resource "aws_subnet" "public_subnet_b" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = var.public_subnet_b_cidr
  availability_zone       = var.availability_zone_b
  map_public_ip_on_launch = true

  tags = {
    Name = "${local.name_prefix}-public-b"
  }
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main_vpc.id

  tags = {
    Name = "${local.name_prefix}-public-rt"
  }
}

resource "aws_route" "public_internet_access" {
  route_table_id         = aws_route_table.public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route_table_association" "public_rt_a" {
  subnet_id      = aws_subnet.public_subnet_a.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_rt_b" {
  subnet_id      = aws_subnet.public_subnet_b.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_eip" "nat_eip_a" {
  domain = "vpc"

  tags = {
    Name = "${local.name_prefix}-nat-eip-a"
  }
}

resource "aws_eip" "nat_eip_b" {
  domain = "vpc"

  tags = {
    Name = "${local.name_prefix}-nat-eip-b"
  }
}

resource "aws_nat_gateway" "nat_a" {
  allocation_id = aws_eip.nat_eip_a.id
  subnet_id     = aws_subnet.public_subnet_a.id

  depends_on = [aws_internet_gateway.igw]

  tags = {
    Name = "${local.name_prefix}-nat-a"
  }
}

resource "aws_nat_gateway" "nat_b" {
  allocation_id = aws_eip.nat_eip_b.id
  subnet_id     = aws_subnet.public_subnet_b.id

  depends_on = [aws_internet_gateway.igw]

  tags = {
    Name = "${local.name_prefix}-nat-b"
  }
}

resource "aws_route" "private_a_default" {
  route_table_id         = aws_route_table.private_rt_a.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat_a.id
}

resource "aws_route" "private_b_default" {
  route_table_id         = aws_route_table.private_rt_b.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat_b.id
}
