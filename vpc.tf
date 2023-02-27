resource "aws_vpc" "contest_vpc" {
  cidr_block = var.vpc_cidr_block

  tags = {
    Name = "contest-vpc"
  }
}

resource "aws_internet_gateway" "contest_internet_gateway" {
  vpc_id = aws_vpc.contest_vpc.id
}

resource "aws_subnet" "public_subnet_1" {
  vpc_id                  = aws_vpc.contest_vpc.id
  cidr_block              = var.public_subnet_1_cidr
  availability_zone       = "eu-west-3a"
  map_public_ip_on_launch = true
  tags = {
    Name = "contest-public-subnet-1"
  }
}

resource "aws_subnet" "public_subnet_2" {
  vpc_id                  = aws_vpc.contest_vpc.id
  cidr_block              = var.public_subnet_2_cidr
  availability_zone       = "eu-west-3b"
  map_public_ip_on_launch = true

  tags = {
    Name = "contest-public-subnet-2"
  }
}

resource "aws_route_table" "contest_public_route_table" {
  vpc_id = aws_vpc.contest_vpc.id
}

resource "aws_route" "contest_public_route" {
  route_table_id         = aws_route_table.contest_public_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.contest_internet_gateway.id
}

resource "aws_route_table_association" "contest_public_route_table_association_subnet_1" {
  subnet_id      = aws_subnet.public_subnet_1.id
  route_table_id = aws_route_table.contest_public_route_table.id
}

resource "aws_route_table_association" "contest_public_route_table_association_subnet_2" {
  subnet_id      = aws_subnet.public_subnet_2.id
  route_table_id = aws_route_table.contest_public_route_table.id
}

resource "aws_subnet" "private_subnet_1" {
  vpc_id            = aws_vpc.contest_vpc.id
  cidr_block        = var.private_subnet_1_cidr
  availability_zone = "eu-west-3a"

  tags = {
    Name = "contest-private-subnet-1"
  }
}

resource "aws_subnet" "private_subnet_2" {
  vpc_id            = aws_vpc.contest_vpc.id
  cidr_block        = var.private_subnet_2_cidr
  availability_zone = "eu-west-3b"

  tags = {
    Name = "contest-private-subnet-2"
  }
}

resource "aws_nat_gateway" "aws_nat_gateway_public_subnet_1" {
  allocation_id = aws_eip.nat_eip_public_subnet_1.id
  subnet_id     = aws_subnet.public_subnet_1.id
  depends_on    = [aws_internet_gateway.contest_internet_gateway]
}

resource "aws_eip" "nat_eip_public_subnet_1" {
  vpc = true
}

resource "aws_nat_gateway" "aws_nat_gateway_public_subnet_2" {
  allocation_id = aws_eip.nat_eip_public_subnet_2.id
  subnet_id     = aws_subnet.public_subnet_2.id
  depends_on    = [aws_internet_gateway.contest_internet_gateway]
}

resource "aws_eip" "nat_eip_public_subnet_2" {
  vpc = true
}

resource "aws_route_table" "contest_private_route_table_1" {
  vpc_id = aws_vpc.contest_vpc.id
}

resource "aws_route" "contest_private_route_1" {
  route_table_id         = aws_route_table.contest_private_route_table_1.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.aws_nat_gateway_public_subnet_1.id
}

resource "aws_route_table_association" "contest_private_route_table_association_subnet_1" {
  subnet_id      = aws_subnet.private_subnet_1.id
  route_table_id = aws_route_table.contest_private_route_table_1.id
}

resource "aws_route_table" "contest_private_route_table_2" {
  vpc_id = aws_vpc.contest_vpc.id
}

resource "aws_route" "contest_private_route_2" {
  route_table_id         = aws_route_table.contest_private_route_table_2.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.aws_nat_gateway_public_subnet_2.id
}

resource "aws_route_table_association" "contest_private_route_table_association_subnet_2" {
  subnet_id      = aws_subnet.private_subnet_2.id
  route_table_id = aws_route_table.contest_private_route_table_2.id
}

resource "aws_security_group" "contest_lb_sg" {
  name   = "contest-lb-sg"
  vpc_id = aws_vpc.contest_vpc.id

  ingress {
    description = "allow access from internet to lb on port 80"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "contest_ecs_sg" {
  name   = "contest-ecs-sg"
  vpc_id = aws_vpc.contest_vpc.id

  ingress {
    description     = "allow access from lb to ecs tasks on port"
    from_port       = 8000
    to_port         = 8000
    protocol        = "tcp"
    security_groups = [aws_security_group.contest_lb_sg.id]
  }
  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

