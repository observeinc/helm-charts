terraform {
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.8.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.17.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.52.0"
    }
  }
  required_version = "~> 1.3"
}

provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
  }
}


provider "kubernetes" {
  config_path = "~/.kube/config"
}

# Create provider_override.tf with the following for local use 
# provider "aws" {
#   region = var.region # Specify the AWS region
#   profile = "blunderdome"
#   assume_role {
#     role_arn = var.cluster_role_arn
#   }
# }

provider "aws" {}

