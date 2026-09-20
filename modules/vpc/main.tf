locals {
  name_prefix = "${var.project_name}-${var.environment}"

  common_tags = merge(
    var.custom_tags,
    {
      Environment = var.environment
      Project     = var.project_name
      ManagedBy   = "Terraform"
      Module      = "terraform-aws-network"
    }
  )
}

# 1. Create the Isolated VPC
resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(local.common_tags, { Name = "${local.name_prefix}-vpc" })
}

resource "aws_subnet" "public" {
  for_each = var.public_subnets

  vpc_id                  = aws_vpc.this.id
  cidr_block              = each.value
  availability_zone       = each.key
  map_public_ip_on_launch = true

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-public-${each.key}"

      # Used by the AWS Load Balancer Controller to discover
      # subnets for internet-facing load balancers.
      "kubernetes.io/role/elb" = "1"
    }
  )
}

# 3. Create a Security Group attached to the VPC
resource "aws_security_group" "this" {
  name        = "${local.name_prefix}-ec2-sg"
  description = "Managed by Terraform: Controls access to the EC2 instances"
  vpc_id      = aws_vpc.this.id

  # Ingress rule: Allow inbound SSH traffic
  ingress {
    description = "Allow SSH from anywhere for testing"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Egress rule: Allow all outbound internet traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, { Name = "${local.name_prefix}-sg" })
}


resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-igw"
    }
  )
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-public-rt"
    }
  )
}

resource "aws_route_table_association" "public" {
  for_each = aws_subnet.public

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}