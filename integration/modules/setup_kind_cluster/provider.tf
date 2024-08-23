terraform {
  required_providers {
    kind = {
      source = "tehcyx/kind"
      version = "0.6.0"
    }
  }
}

provider "kind" {}

provider "kubernetes" {
  config_path = pathexpand(var.kind_cluster_config_path)
}