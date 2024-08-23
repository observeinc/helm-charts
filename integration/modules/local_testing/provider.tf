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
    kind = {
      source = "tehcyx/kind"
      version = "0.6.0"
    }
  }
  required_version = "~> 1.3"
}
