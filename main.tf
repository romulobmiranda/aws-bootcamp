terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 3.27"
    }
  }
}

variable "key_name" {}

provider "aws" {
  profile = "default"
  region     = "us-east-2"
}

# CRIAR VPC
resource "aws_vpc" "vpc-bootcamp" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_vpc" "vpc-bastion" {
  cidr_block = "10.1.0.0/16"
}

#CRIAR PEERING ENTRE VPCS
resource "aws_vpc_peering_connection" "conexao-vpcs" {
  peer_vpc_id = aws_vpc.vpc-bootcamp.id
  vpc_id = aws_vpc.vpc-bastion.id
  auto_accept = true
}

resource "aws_vpc_peering_connection_options" "conexao-vpcs" {
  vpc_peering_connection_id = aws_vpc_peering_connection.conexao-vpcs.id

  accepter {
    allow_remote_vpc_dns_resolution = true
  }

  requester {
    allow_vpc_to_remote_classic_link = true
    allow_classic_link_to_remote_vpc = true
  }
}

#CRIAR SUBNET PÚBLICA - BASTION
resource "aws_subnet" "bastion-subnet" {
  vpc_id = aws_vpc.vpc-bastion.id
  cidr_block = "10.1.1.0/24"
}

resource "aws_route_table" "bastion-subnet" {
  vpc_id = aws_vpc.vpc-bastion.id
}

resource "aws_route_table_association" "bastion-subnet" {
  subnet_id = aws_subnet.bastion-subnet.id
  route_table_id = aws_route_table.bastion-subnet.id
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
resource "aws_security_group" "acessords" {
  name = "acessords"
#vpc_id = aws_vpc.vpc-bootcamp.id

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

resource "aws_security_group" "acessoapp" {
  name = "acessoapp"
#vpc_id = aws_vpc.vpc-bootcamp.id

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["10.1.0.0/16"]
  }

  egress {
    from_port = 80
    to_port = 80
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "bastion-sg" {
  name   = "bastion-security-group"
#vpc_id = aws_vpc.vpc-bastion.id

  ingress {
    protocol    = "tcp"
    from_port   = 22
    to_port     = 22
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#GERAR SSH KEYS
resource "tls_private_key" "example" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "private_key" {
  content = tls_private_key.example.private_key_pem
  filename = "private_key.pem"
  file_permission = "0600"
}

resource "aws_key_pair" "generated_key" {
  key_name   = var.key_name
  public_key = tls_private_key.example.public_key_openssh
}

#CRIAR A INSTÂNCIA DO APP
resource "aws_instance" "app_server" {
  ami           = "ami-0747bdcabd34c712a"
  instance_type = "t2.micro"
  subnet_id = aws_subnet.public-subnet.id
  vpc_security_group_ids = [aws_security_group.acessoapp.id]
}

resource "aws_instance" "bastion" {
  ami           = "ami-0747bdcabd34c712a"
  instance_type = "t2.micro"
  subnet_id = aws_subnet.bastion-subnet.id
  key_name = aws_key_pair.generated_key.key_name
  vpc_security_group_ids = [aws_security_group.bastion-sg.id]
}

# CRIAR INSTÂNCIA RDS
resource "aws_db_instance" "bdrds" {
  allocated_storage = 20
  engine = "mysql"
  engine_version = "5.7.30"
  instance_class = "db.t2.micro"
  name = "awsuserdb01"
  username = "Admin"
  password = "Admin123456"
  port = "3306"
  storage_type = "gp2"
  security_group_names = [aws_security_group.acessords.id]
}  