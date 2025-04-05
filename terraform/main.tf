# Configure the AWS Provider
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# ---------------------------------------------------------------------------------------------------------------------
# Variables
# ---------------------------------------------------------------------------------------------------------------------

variable "aws_region" {
  type        = string
  description = "AWS region to deploy to"
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR block for the VPC"
  default     = "10.0.0.0/16"
}

variable "public_subnet_1_cidr" {
  type        = string
  description = "CIDR block for the first public subnet"
  default     = "10.0.1.0/24"
}

variable "public_subnet_2_cidr" {
  type        = string
  description = "CIDR block for the second public subnet"
  default     = "10.0.2.0/24"
}

variable "private_subnet_1_cidr" {
  type        = string
  description = "CIDR block for the first private subnet"
  default     = "10.0.3.0/24"
}

variable "private_subnet_2_cidr" {
  type        = string
  description = "CIDR block for the second private subnet"
  default     = "10.0.4.0/24"
}

variable "availability_zone_1" {
  type        = string
  description = "Availability Zone for the first set of subnets"
  default     = "ap-southeast-1a"
}

variable "availability_zone_2" {
  type        = string
  description = "Availability Zone for the second set of subnets"
  default     = "ap-southeast-1b"
}

variable "eks_cluster_name" {
  type        = string
  description = "Name of the EKS cluster"
  default     = "eks-cluster"
}

variable "eks_node_group_name" {
  type        = string
  description = "Name of the EKS node group"
  default     = "eks-node-group"
}

variable "eks_node_instance_type" {
  type        = string
  description = "Instance type for the EKS nodes"
  default     = "t2.medium"
}

variable "eks_node_desired_size" {
  type        = number
  description = "Desired number of EKS nodes"
  default     = 2
}

variable "eks_node_max_size" {
  type        = number
  description = "Maximum number of EKS nodes"
  default     = 3
}

variable "eks_node_min_size" {
  type        = number
  description = "Minimum number of EKS nodes"
  default     = 1
}

variable "container_image" {
  type        = string
  description = "Docker image to deploy"
  default     = "arun1771/my-sts-app:v2"
}

variable "container_port" {
  type        = number
  description = "Port the container application listens on"
  default     = 5000
}

variable "service_port" {
  type        = number
  description = "Port to expose the service on the Load Balancer"
  default     = 80
}

variable "deployment_replicas" {
  type        = number
  description = "Number of deployment replicas"
  default     = 4
}

# ---------------------------------------------------------------------------------------------------------------------
# VPC and Subnets
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "eks-vpc"
  }
}

# Public Subnets
resource "aws_subnet" "public_subnet_1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.public_subnet_1_cidr
  availability_zone = var.availability_zone_1
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet-1"
  }
}

resource "aws_subnet" "public_subnet_2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.public_subnet_2_cidr
  availability_zone = var.availability_zone_2
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet-2"
  }
}

# Private Subnets
resource "aws_subnet" "private_subnet_1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_1_cidr
  availability_zone = var.availability_zone_1

  tags = {
    Name = "private-subnet-1"
  }
}

resource "aws_subnet" "private_subnet_2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_2_cidr
  availability_zone = var.availability_zone_2

  tags = {
    Name = "private-subnet-2"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "eks-igw"
  }
}

# Route Table for Public Subnets
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "public-route-table"
  }
}

# Route Table Associations for Public Subnets
resource "aws_route_table_association" "public_subnet_1_assoc" {
  subnet_id      = aws_subnet.public_subnet_1.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "public_subnet_2_assoc" {
  subnet_id      = aws_subnet.public_subnet_2.id
  route_table_id = aws_route_table.public_route_table.id
}

# NAT Gateway (for private subnets to access the internet)
resource "aws_nat_gateway" "nat_gateway" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnet_1.id # Put NAT gateway in a public subnet

  tags = {
    Name = "eks-nat-gateway"
  }

  depends_on = [aws_internet_gateway.gw]
}

resource "aws_eip" "nat_eip" {
  domain = "vpc"
}

# Route Table for Private Subnets
resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block    = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gateway.id
  }

  tags = {
    Name = "private-route-table"
  }
}

# Route Table Associations for Private Subnets
resource "aws_route_table_association" "private_subnet_1_assoc" {
  subnet_id      = aws_subnet.private_subnet_1.id
  route_table_id = aws_route_table.private_route_table.id
}

resource "aws_route_table_association" "private_subnet_2_assoc" {
  subnet_id      = aws_subnet.private_subnet_2.id
  route_table_id = aws_route_table.private_route_table.id
}

# ---------------------------------------------------------------------------------------------------------------------
# EKS Cluster
# ---------------------------------------------------------------------------------------------------------------------

# EKS Cluster Role
resource "aws_iam_role" "eks_cluster_role" {
  name = "${var.eks_cluster_name}-role"
  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "eks.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}

# EKS Cluster Policy Attachment
resource "aws_iam_policy_attachment" "eks_cluster_policy_attachment" {
  name       = "${var.eks_cluster_name}-cluster-policy-attachment"
  roles      = [aws_iam_role.eks_cluster_role.name]
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# EKS Node Group Role
resource "aws_iam_role" "eks_node_group_role" {
  name = "${var.eks_node_group_name}-role"
  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}

# EKS Node Group Policy Attachments
resource "aws_iam_policy_attachment" "eks_node_group_policy_attachment_1" {
  name       = "${var.eks_node_group_name}-worker-policy-attachment"
  roles      = [aws_iam_role.eks_node_group_role.name]
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_policy_attachment" "eks_node_group_policy_attachment_2" {
  name       = "${var.eks_node_group_name}-cni-policy-attachment"
  roles      = [aws_iam_role.eks_node_group_role.name]
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_policy_attachment" "eks_node_group_policy_attachment_3" {
  name       = "${var.eks_node_group_name}-ecr-read-only-policy-attachment"
  roles      = [aws_iam_role.eks_node_group_role.name]
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# EKS Cluster
resource "aws_eks_cluster" "eks_cluster" {
  name     = var.eks_cluster_name
  role_arn = aws_iam_role.eks_cluster_role.arn
  vpc_config {
    subnet_ids = [
      aws_subnet.private_subnet_1.id,
      aws_subnet.private_subnet_2.id,
      aws_subnet.public_subnet_1.id,
      aws_subnet.public_subnet_2.id
    ]
    security_group_ids = [aws_security_group.eks_cluster_sg.id]
  }

  depends_on = [
    aws_iam_policy_attachment.eks_cluster_policy_attachment,
    aws_iam_policy_attachment.eks_node_group_policy_attachment_1,
    aws_iam_policy_attachment.eks_node_group_policy_attachment_2,
    aws_iam_policy_attachment.eks_node_group_policy_attachment_3
  ]
}

# Security Group for EKS Cluster
resource "aws_security_group" "eks_cluster_sg" {
  name        = "${var.eks_cluster_name}-sg"
  description = "Security group for EKS cluster"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # All protocols
    cidr_blocks = [var.vpc_cidr] # Allow communication within the VPC
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # All protocols
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.eks_cluster_name}-sg"
  }
}


# EKS Node Group - Deployed to Private Subnets
resource "aws_eks_node_group" "eks_node_group" {
  cluster_name    = aws_eks_cluster.eks_cluster.name
  node_group_name = var.eks_node_group_name
  node_role_arn   = aws_iam_role.eks_node_group_role.arn
  subnet_ids      = [aws_subnet.private_subnet_1.id, aws_subnet.private_subnet_2.id]  # IMPORTANT: Private Subnets ONLY
  instance_types  = [var.eks_node_instance_type]

  scaling_config {
    desired_size = var.eks_node_desired_size
    max_size     = var.eks_node_max_size
    min_size     = var.eks_node_min_size
  }

  update_config {
    max_unavailable = 1
  }

  depends_on = [aws_eks_cluster.eks_cluster]
}

# ------------------------------------------------------------------------------
# Kubernetes Provider Configuration
# ------------------------------------------------------------------------------

data "aws_eks_cluster_auth" "cluster" {
  name = aws_eks_cluster.eks_cluster.name
}

provider "kubernetes" {
  host                   = aws_eks_cluster.eks_cluster.endpoint
  token                  = data.aws_eks_cluster_auth.cluster.token
  cluster_ca_certificate = base64decode(aws_eks_cluster.eks_cluster.certificate_authority[0].data)
}

provider "helm" {
  kubernetes {
    host                   = aws_eks_cluster.eks_cluster.endpoint
    token                  = data.aws_eks_cluster_auth.cluster.token
    cluster_ca_certificate = base64decode(aws_eks_cluster.eks_cluster.certificate_authority[0].data)
  }
}

# ------------------------------------------------------------------------------
# Kubernetes Deployment and Service
# ------------------------------------------------------------------------------

resource "kubernetes_deployment" "app_deployment" {
  metadata {
    name = "my-sts-app-deployment"
    labels = {
      app = "my-sts-app"
    }
  }
  spec {
    replicas = var.deployment_replicas
    selector {
      match_labels = {
        app = "my-sts-app"
      }
    }
    template {
      metadata {
        labels = {
          app = "my-sts-app"
        }
      }
      spec {
        container {
          image = var.container_image
          name  = "my-sts-app-container"
          port {
            container_port = var.container_port
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "app_service" {
  metadata {
    name = "my-sts-app-service"
    annotations = {
      "service.beta.kubernetes.io/aws-load-balancer-type" = "nlb" # Use "nlb" for Network Load Balancer, "elb" for Classic
      "kubernetes.io/ingress.class"                       = "alb" # Remove if not using ALB
      "alb.ingress.kubernetes.io/scheme"                  = "internet-facing" # Remove if not using ALB
    }
  }
  spec {
    selector = {
      app = "my-sts-app"
    }
    port {
      port        = var.service_port
      target_port = var.container_port
      protocol    = "TCP"
    }
    type = "LoadBalancer"
  }
}
