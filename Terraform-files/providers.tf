# Configure the AWS Provider
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"   # Adjust to the latest compatible version
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"    # Adjust to the latest compatible version
    }
  }
}

provider "aws" {
  region = "ap-southeast-1" # Replace with your desired AWS region
}
