terraform {
  required_version = ">= 1.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_vpc" "flowkit" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = { Name = "${var.name_prefix}-vpc" }
}

resource "aws_internet_gateway" "flowkit" {
  vpc_id = aws_vpc.flowkit.id
  tags   = { Name = "${var.name_prefix}-igw" }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.flowkit.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "${var.aws_region}a"
  tags = { Name = "${var.name_prefix}-public" }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.flowkit.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.flowkit.id
  }
  tags = { Name = "${var.name_prefix}-rt" }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_security_group" "flowkit" {
  name_prefix = "${var.name_prefix}-"
  vpc_id      = aws_vpc.flowkit.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.ssh_allowed_cidr]
  }
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = [var.api_allowed_cidr]
  }
  ingress {
    from_port   = 6080
    to_port     = 6579
    protocol    = "tcp"
    cidr_blocks = var.vnc_allowed_cidr == "" ? [] : [var.vnc_allowed_cidr]
  }
  ingress {
    from_port   = 5901
    to_port     = 5999
    protocol    = "tcp"
    cidr_blocks = var.vnc_allowed_cidr == "" ? [] : [var.vnc_allowed_cidr]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = { Name = "${var.name_prefix}-sg" }
}

resource "aws_instance" "worker" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  key_name                    = var.ssh_key_name
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.flowkit.id]
  associate_public_ip_address = true

  user_data = templatefile("${path.module}/user-data.sh", {
    repo_url             = var.repo_url
    repo_branch          = var.repo_branch
    worker_id            = var.worker_id
    orchestrator_url     = var.orchestrator_url
    orchestrator_api_key = var.orchestrator_api_key
    redis_url            = var.redis_url
    vnc_password         = var.vnc_password
    app_dir              = var.app_dir
  })

  root_block_device {
    volume_size = var.disk_size_gb
    volume_type = "gp3"
  }

  tags = { Name = "${var.name_prefix}-worker" }
}
