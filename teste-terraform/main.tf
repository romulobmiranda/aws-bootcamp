terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 3.27"
    }
  }
}

variable = id {}
variable = secret_key {}

provider "aws" {
  profile = "default"
  region     = "us-east-1"
}

# CRIAR VPC
resource "aws_vpc" "vpc-bootcamp" {
  cidr_block = "10.0.0.0/16"
}

#CRIAR SUBNET PRIVADA
resource "aws_subnet" "priv-subnet" {
  vpc_id     = aws_vpc.vpc-bootcamp.id
  cidr_block = "10.0.1.0/24"
}

resource "aws_route_table" "priv-subnet" {
  vpc_id     = aws_vpc.vpc-bootcamp.id  
}

resource "aws_route_table_association" "priv-subnet" {
  subnet_id = aws_subnet.priv-subnet.id
  route_table_id = aws_route_table.priv-subnet.id
}

#CRIAR SUBNET PÚBLICA
resource "aws_subnet" "public-subnet" {
  vpc_id     = aws_vpc.vpc-bootcamp.id
  cidr_block = "10.0.2.0/24"
  map_public_ip_on_launch = "true"
}

resource "aws_route_table" "public-subnet" {
  vpc_id     = aws_vpc.vpc-bootcamp.id  
}

resource "aws_route_table_association" "public-subnet" {
  subnet_id = aws_subnet.public-subnet.id
  route_table_id = aws_route_table.public-subnet.id
}

#CRIAR O GRUPO DE SEGURANÇA
resource "aws_security_group" "acessoapp" {
    name = "acessoapp"
    vpc_id = aws_vpc.vpc-bootcamp.id

    ingress {
        from_port = 3306
        to_port = 3306
        protocol = "tcp"
        cidr_blocks = ["10.0.0.0/16"]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

#CRIAR A INSTÂNCIA DO APP
resource "aws_instance" "app_server" {
  ami           = "ami-08353a25e80beea3e"
  instance_type = "t2.micro"
  subnet_id = aws_subnet.public-subnet.id
}

# CRIAR INSTÂNCIA RDS
resource "aws_db_instance" "bdrds"
  allocated_storage = 20
  engine = "mysql"
  engine_version = "5.7.30"
  instance_class = "db.t2.micro"
  name = "awsuserdb01"
  username = "Admin"
  password = "Admin123456"
  port = "3306"
  db_subnet_group_name = aws_subnet.priv-subnet.id
  storage_type = "gp2"