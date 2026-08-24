terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

# --- Network Infrastructure ---

resource "aws_vpc" "vpc" {
  cidr_block           = var.address_space[0] # e.g. "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = merge(local.tags, { Name = var.vnet_name })
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
  tags   = merge(local.tags, { Name = "igw-${var.vnet_name}" })
}

resource "aws_subnet" "subnet" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = var.subnet_prefix[0] # e.g. "10.0.1.0/24"
  map_public_ip_on_launch = true
  tags                    = merge(local.tags, { Name = "subnet-main" })
}

resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = merge(local.tags, { Name = "rt-main" })
}

resource "aws_route_table_association" "rta" {
  subnet_id      = aws_subnet.subnet.id
  route_table_id = aws_route_table.rt.id
}

# --- Security Group (NSG Equivalent) ---

resource "aws_security_group" "sg" {
  name        = "nsg-main"
  description = "Security group for VM"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    description = "Allow SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_ips
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.tags
}

# --- SSH Key & AMI Resolution ---

resource "aws_key_pair" "auth" {
  key_name   = "${var.vm_name}-key"
  public_key = file(pathexpand(var.pubkey))
  tags       = local.tags
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# --- Compute (EC2 Instance) ---

resource "aws_instance" "vm" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.vm_size # e.g. "t3.small" or "t2.micro"
  subnet_id                   = aws_subnet.subnet.id
  vpc_security_group_ids      = [aws_security_group.sg.id]
  key_name                    = aws_key_pair.auth.key_name
  associate_public_ip_address = true

metadata_options {
  http_endpoint = "enabled"
  http_tokens = "required"
  http_put_response_hop_limit = 1
  instance_metadata_tags = "disabled"
}

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 30
    delete_on_termination = true
  }

  tags = merge(local.tags, { Name = var.vm_name })
}