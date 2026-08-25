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

# ----------------------------------------------------------------------
# 1. VPC & Subnets
# ----------------------------------------------------------------------
resource "aws_vpc" "vpc" {
  cidr_block           = var.address_space # e.g., "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(local.tags, {
    Name = var.vnet_name
  })
}

# Public subnet required to host the NAT Gateway
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = cidrsubnet(var.address_space, 8, 100) # e.g., "10.0.100.0/24"
  map_public_ip_on_launch = true

  tags = merge(local.tags, {
    Name = "subnet-public-nat"
  })
}

# Private subnet equivalent to Azure subnet
resource "aws_subnet" "subnet" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = var.subnet_prefix # e.g., "10.0.1.0/24"
  availability_zone       = aws_subnet.public.availability_zone
  map_public_ip_on_launch = false

  tags = merge(local.tags, {
    Name = "subnet-main"
  })
}

# Internet Gateway for VPC public outbound traffic
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags = merge(local.tags, {
    Name = "igw-${var.vm_name}"
  })
}

# Public Route Table (directs IGW traffic)
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = merge(local.tags, {
    Name = "rt-public"
  })
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# ----------------------------------------------------------------------
# 2. NAT Gateway & Elastic IP (Outbound connectivity for private subnet)
# ----------------------------------------------------------------------
resource "aws_eip" "nat" {
  domain = "vpc"

  tags = merge(local.tags, {
    Name = "pip-${var.vm_name}"
  })
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public.id

  tags = merge(local.tags, {
    Name = "natgw-${var.vm_name}"
  })

  depends_on = [aws_internet_gateway.igw]
}

# Private Route Table (routes outbound traffic through NAT Gateway)
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = merge(local.tags, {
    Name = "rt-private"
  })
}

resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.subnet.id
  route_table_id = aws_route_table.private.id
}

# ----------------------------------------------------------------------
# 3. Security Group & Key Pair
# ----------------------------------------------------------------------
resource "aws_security_group" "sg" {
  name        = "nsg-main"
  description = "Main network security group"
  vpc_id      = aws_vpc.vpc.id

  # Allow all outbound traffic (matches Azure NSG default behavior)
  egress {
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
    description      = "allow outband HTTPS traffic"
  }

  egress {
    from_port   = 41641
    to_port     = 41641
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Direct Wireguard Traffic"
  }

  egress {
    from_port   = 3478
    to_port     = 3478
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Tailscale STUN NAT"
  }

  egress {
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "DNS"
  }

  tags = merge(local.tags, {
    Name = "nsg-main"
  })
}

resource "aws_key_pair" "key" {
  key_name   = "key-${var.vm_name}"
  public_key = file(pathexpand(var.pubkey))

  tags = local.tags
}

# ----------------------------------------------------------------------
# 4. AMI & EC2 Instance
# ----------------------------------------------------------------------
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

resource "aws_instance" "vm" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.vm_size
  subnet_id     = aws_subnet.subnet.id
  key_name      = aws_key_pair.key.key_name

  vpc_security_group_ids = [
    aws_security_group.sg.id
  ]

  user_data = templatefile("${path.root}/../../common/cloud-init.yaml", {
    tailnet-key = var.tailnet-key
    hostname    = var.vm_name
  })

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 30
    delete_on_termination = true
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required" # Fixes CKV_AWS_79
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "enabled"
  }

  tags = merge(local.tags, {
    Name = var.vm_name
  })
}
