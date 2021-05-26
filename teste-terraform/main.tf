# Configure the AWS Provider
terraform {
  require_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 3.27"
    }
  }
}

provider "aws" {
  profile = "default"
  region     = "us-east-1"
}

# Create a VPC
resource "aws_vpc" "vpc-bootcamp" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "priv-subnet" {
  vpc_id     = var.priv_id
  cidr_block = "10.0.1.0/24"
}

resource "aws_route_table" "priv-subnet" {
  vpc_id     = var.priv_id  
}

resource "aws_route_table_association" "priv-subnet" {
  subnet_id = aws_subnet.priv-subnet.id
  route_table_id = aws_route_table_association.id
}