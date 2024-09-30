provider "aws" {
  region = "us-east-1"
}

resource "aws_instance" "app-vm" {
  ami           = "ami-0c7217cdde317cfec"
  instance_type = "t2.micro"
  key_name      = "vpckey"

  subnet_id              = aws_subnet.my-public-subnet-1.id
  vpc_security_group_ids = [aws_security_group.my-sg1.id]

  for_each = toset(["ansible-server", "jenkins-master", "jenkins-slave"])
  tags = {
    Name = "${each.key}"
  }
}

resource "aws_vpc" "my-vpc" {
  cidr_block = "192.168.0.0/16"
  tags = {
    Name = "my-vpc"
  }
}

resource "aws_subnet" "my-public-subnet-1" {
  vpc_id                  = aws_vpc.my-vpc.id
  cidr_block              = "192.168.1.0/24"
  map_public_ip_on_launch = "true"
  availability_zone       = "us-east-1a"
  tags = {
    Name = "my-public-subent-01"
  }
}

resource "aws_security_group" "my-sg1" {
  name        = "my-sg1"
  description = "SSH Access"
  vpc_id      = aws_vpc.my-vpc.id

  ingress {
    description = "Shh access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ssh-prot"
  }
}

resource "aws_internet_gateway" "my-igw" {
  vpc_id = aws_vpc.my-vpc.id
  tags = {
    Name = "my-igw"
  }
}

resource "aws_route_table" "my-public-rt" {
  vpc_id = aws_vpc.my-vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my-igw.id
  }
}

resource "aws_route_table_association" "my-rta-public-subnet-1" {
  subnet_id      = aws_subnet.my-public-subnet-1.id
  route_table_id = aws_route_table.my-public-rt.id
}

