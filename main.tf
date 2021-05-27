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

#GERAR SSH KEYS
resource "tls_private_key" "example" {
  algorithm = "RSA"
  rsa_bits  = 4096
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
  key_name = aws_key_pair.generated_key.key_name

      connection {
      type = "ssh"
      user = "ec2-user"
      host = self.public_ip
      private_key = "${file("~/.ssh/authorized_keys)}"
    }

  provisioner "remote-exec" {  
    inline = ["sudo apt-get update", 
    "sudo apt-get install python3-dev", 
    "sudo apt-get install libmysqlclient-dev", 
    "sudo apt-get install unzip", 
    "sudo apt-get install libpq-dev",
    "sudo apt-get install python-dev",
    "sudo apt-get install libxml2-dev",
    "sudo apt-get install libxslt1-dev", 
    "sudo apt-get install libldap2-dev", 
    "sudo apt-get install libsasl2-dev",
    "sudo apt-get install libffi-dev"]
  }
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
}  