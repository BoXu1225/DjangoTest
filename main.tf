terraform {
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

# Data source for Ubuntu 20.04 AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# VPC - Virtual Private Cloud
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "django-celery-vpc"
  }
}

# Public Subnet
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "django-celery-public-subnet"
  }
}

# Private Subnet for Redis
resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = data.aws_availability_zones.available.names[1]

  tags = {
    Name = "django-celery-private-subnet"
  }
}

# Data source for availability zones
data "aws_availability_zones" "available" {
  state = "available"
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "django-celery-igw"
  }
}

# Route Table for Public Subnet
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "django-celery-public-route-table"
  }
}

# Associate Route Table with Public Subnet
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# Security Group for Web Servers
resource "aws_security_group" "web_server" {
  name        = "django-web-server-sg"
  description = "Security group for Django web servers"
  vpc_id      = aws_vpc.main.id

  # HTTP access from anywhere
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # SSH access
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.my_ip != null ? ["${var.my_ip}/32"] : ["0.0.0.0/0"]
  }

  # All outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "django-web-server-sg"
  }
}

# Security Group for Processing Server
resource "aws_security_group" "processing_server" {
  name        = "django-processing-server-sg"
  description = "Security group for Celery processing server"
  vpc_id      = aws_vpc.main.id

  # SSH access
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.my_ip != null ? ["${var.my_ip}/32"] : ["0.0.0.0/0"]
  }

  # All outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "django-processing-server-sg"
  }
}

# Security Group for Redis
resource "aws_security_group" "redis" {
  name        = "django-redis-sg"
  description = "Security group for Redis ElastiCache"
  vpc_id      = aws_vpc.main.id

  # Redis access from web servers and processing server
  ingress {
    description     = "Redis from web servers"
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [aws_security_group.web_server.id, aws_security_group.processing_server.id]
  }

  tags = {
    Name = "django-redis-sg"
  }
}

# ElastiCache Subnet Group
resource "aws_elasticache_subnet_group" "redis" {
  name       = "django-redis-subnet-group"
  subnet_ids = [aws_subnet.public.id, aws_subnet.private.id]

  tags = {
    Name = "django-redis-subnet-group"
  }
}

# ElastiCache Redis Cluster
resource "aws_elasticache_cluster" "redis" {
  cluster_id           = "django-redis"
  engine               = "redis"
  node_type            = "cache.t2.micro"
  num_cache_nodes      = 1
  parameter_group_name = "default.redis7"
  port                 = 6379
  subnet_group_name    = aws_elasticache_subnet_group.redis.name
  security_group_ids   = [aws_security_group.redis.id]

  tags = {
    Name = "django-redis"
  }
}

# Security Group for RDS Database
resource "aws_security_group" "database" {
  name        = "django-database-sg"
  description = "Security group for PostgreSQL database"
  vpc_id      = aws_vpc.main.id

  # PostgreSQL access from web servers and processing server
  ingress {
    description     = "PostgreSQL from application servers"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.web_server.id, aws_security_group.processing_server.id]
  }

  tags = {
    Name = "django-database-sg"
  }
}

# DB Subnet Group
resource "aws_db_subnet_group" "database" {
  name       = "django-db-subnet-group"
  subnet_ids = [aws_subnet.public.id, aws_subnet.private.id]

  tags = {
    Name = "django-db-subnet-group"
  }
}

# RDS PostgreSQL Databases (one per web server)
resource "aws_db_instance" "postgres" {
  count                  = 2
  identifier             = "django-postgres-${count.index + 1}"
  engine                = "postgres"
  engine_version        = "15.7"
  instance_class        = "db.t3.micro"
  allocated_storage     = 20
  storage_type          = "gp2"

  db_name  = "djangodb"
  username = "django_user"
  password = "django_password_123"  # In production, use AWS Secrets Manager

  vpc_security_group_ids = [aws_security_group.database.id]
  db_subnet_group_name   = aws_db_subnet_group.database.name

  skip_final_snapshot = true
  deletion_protection = false

  backup_retention_period = 7
  backup_window          = "03:00-04:00"
  maintenance_window     = "sun:04:00-sun:05:00"

  tags = {
    Name = "django-postgres-${count.index + 1}"
  }
}

# Web Servers (2 instances)
resource "aws_instance" "web_server" {
  count                  = 2
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t2.micro"
  key_name               = var.key_pair_name
  vpc_security_group_ids = [aws_security_group.web_server.id]
  subnet_id              = aws_subnet.public.id

  user_data = templatefile("${path.module}/user_data.sh", {
    server_role  = "web"
    server_id    = count.index + 1
    git_repo_url = var.git_repo_url
    redis_url    = "redis://${aws_elasticache_cluster.redis.cache_nodes[0].address}:${aws_elasticache_cluster.redis.cache_nodes[0].port}/0"
    database_url = "postgresql://${aws_db_instance.postgres[count.index].username}:${aws_db_instance.postgres[count.index].password}@${aws_db_instance.postgres[count.index].endpoint}/${aws_db_instance.postgres[count.index].db_name}"
  })

  tags = {
    Name = "django-web-server-${count.index + 1}"
  }

  depends_on = [aws_elasticache_cluster.redis]
}

# Processing Server (1 instance)
resource "aws_instance" "processing_server" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t2.micro"
  key_name               = var.key_pair_name
  vpc_security_group_ids = [aws_security_group.processing_server.id]
  subnet_id              = aws_subnet.public.id

  user_data = templatefile("${path.module}/user_data.sh", {
    server_role   = "celery"
    server_id     = "celery"
    git_repo_url  = var.git_repo_url
    redis_url     = "redis://${aws_elasticache_cluster.redis.cache_nodes[0].address}:${aws_elasticache_cluster.redis.cache_nodes[0].port}/0"
    database_url  = "postgresql://${aws_db_instance.postgres[0].username}:${aws_db_instance.postgres[0].password}@${aws_db_instance.postgres[0].endpoint}/${aws_db_instance.postgres[0].db_name}"
    database_urls = join(",", [for i in range(2) : "postgresql://${aws_db_instance.postgres[i].username}:${aws_db_instance.postgres[i].password}@${aws_db_instance.postgres[i].endpoint}/${aws_db_instance.postgres[i].db_name}"])
  })

  tags = {
    Name = "django-processing-server"
  }

  depends_on = [aws_elasticache_cluster.redis]
}

# Outputs
output "web_server_ips" {
  description = "Public IP addresses of the web servers"
  value       = aws_instance.web_server[*].public_ip
}

output "processing_server_ip" {
  description = "Public IP address of the processing server"
  value       = aws_instance.processing_server.public_ip
}

output "redis_endpoint" {
  description = "Redis cluster endpoint"
  value       = aws_elasticache_cluster.redis.cache_nodes[0].address
}

output "database_endpoints" {
  description = "RDS PostgreSQL database endpoints"
  value       = aws_db_instance.postgres[*].endpoint
}