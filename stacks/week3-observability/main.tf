data "aws_availability_zones" "available" {
  state = "available"
}

# --- AMI: Amazon Linux 2023 ---
data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

locals {
  common_tags = merge(
    {
      Project   = var.project_name
      ManagedBy = "Terraform"
      Stack     = "week2-public-private-vpc"
    },
    var.tags
  )
}

# --- VPC ---
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(local.common_tags, { Name = "${var.project_name}-vpc" })
}

# --- IGW ---
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags   = merge(local.common_tags, { Name = "${var.project_name}-igw" })
}

# --- Subnets ---
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = merge(local.common_tags, { Name = "${var.project_name}-public" })
}

resource "aws_subnet" "private" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.private_subnet_cidr
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = false

  tags = merge(local.common_tags, { Name = "${var.project_name}-private" })
}

# --- Route tables ---
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  tags   = merge(local.common_tags, { Name = "${var.project_name}-rt-public" })
}

resource "aws_route" "public_default" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# --- NAT Gateway (in public subnet) ---
resource "aws_eip" "nat" {
  domain = "vpc"
  tags   = merge(local.common_tags, { Name = "${var.project_name}-eip-nat" })
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public.id

  tags       = merge(local.common_tags, { Name = "${var.project_name}-nat" })
  depends_on = [aws_internet_gateway.igw]
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
  tags   = merge(local.common_tags, { Name = "${var.project_name}-rt-private" })
}

resource "aws_route" "private_default" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat.id
}

resource "aws_route_table_association" "private_assoc" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}

# --- Security groups ---
resource "aws_security_group" "bastion" {
  name        = "${var.project_name}-sg-bastion"
  description = "Bastion: SSH from my IP only"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH from my IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip_cidr]
  }

ingress {
  description = "SSH from monitoring SG"
  from_port   = 22
  to_port     = 22
  protocol    = "tcp"
  security_groups = [aws_security_group.monitoring_sg.id]
}

  # Node Exporter scrape from monitoring host
  ingress {
    description     = "Node Exporter from monitoring SG"
    from_port       = 9100
    to_port         = 9100
    protocol        = "tcp"
    security_groups = [aws_security_group.monitoring_sg.id]
  }

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, { Name = "${var.project_name}-sg-bastion" })
}

resource "aws_security_group" "app" {
  name        = "${var.project_name}-sg-app"
  description = "App (private): SSH only from bastion SG"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "SSH only from bastion"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion.id]
  }

  # Node Exporter scrape from monitoring host
  ingress {
    description     = "Node Exporter from monitoring SG"
    from_port       = 9100
    to_port         = 9100
    protocol        = "tcp"
    security_groups = [aws_security_group.monitoring_sg.id]
  }

  egress {
    description = "All outbound (routes enforce NAT)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, { Name = "${var.project_name}-sg-app" })
}

# --- Security Group: Monitoring (Prometheus + Grafana) ---
resource "aws_security_group" "monitoring_sg" {
  name        = "${var.project_name}-monitoring-sg"
  description = "Allow SSH + Grafana from admin CIDR; Prometheus internal"
  vpc_id      = aws_vpc.main.id

  # SSH from your IP
  ingress {
    description = "SSH from admin IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.admin_cidr]
  }

  # Grafana UI from your IP
  ingress {
    description = "Grafana from admin IP"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = [var.admin_cidr]
  }

  # Prometheus UI (optional). Keep it internal to VPC by default
  ingress {
    description = "Prometheus (VPC only)"
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    description = "Allow all egress"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-monitoring-sg"
  }
}

# --- EC2 instances ---
resource "aws_instance" "bastion" {
  ami                         = data.aws_ami.al2023.id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.bastion.id]
  key_name                    = var.key_name
  associate_public_ip_address = true

  tags = merge(local.common_tags, { Name = "${var.project_name}-bastion" })
}

resource "aws_instance" "app" {
  ami                    = data.aws_ami.al2023.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.private.id
  vpc_security_group_ids = [aws_security_group.app.id]
  key_name               = var.key_name

  tags = merge(local.common_tags, { Name = "${var.project_name}-app-private" })
}

# --- EC2: Monitoring node (public subnet) ---
resource "aws_instance" "monitoring" {
  ami                         = data.aws_ami.al2023.id
  instance_type               = var.monitoring_instance_type
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.monitoring_sg.id]
  associate_public_ip_address = true
  key_name                    = var.key_name

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  tags = {
    Name = "${var.project_name}-monitoring"
    Role = "monitoring"
  }
}
