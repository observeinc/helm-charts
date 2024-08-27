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
  }
  required_version = "~> 1.3"
}

# provider "helm" {
#   kubernetes {
#     config_path = pathexpand("~/.kube/config") 
#   }
# }

# provider "kubernetes" {
#   config_path = pathexpand("~/.kube/config") 
# }
