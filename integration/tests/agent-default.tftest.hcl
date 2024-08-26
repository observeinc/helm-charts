variables {
  cluster_config_path = "~/.kube/config"
}

provider "helm" {
  kubernetes {
    config_path = pathexpand(var.cluster_config_path) #Needed by deploy_helm 
  }
}

provider "kubernetes" {
  config_path = pathexpand(var.cluster_config_path) #Needed by deploy_helm 
} 


run "setup_kind_cluster" {
  variables {
    kind_cluster_config_path=var.cluster_config_path 
  }
  module {
    source = "./modules/setup_kind_cluster"
  }
}

run "deploy_helm" { 
  variables {
    values_file = "default.yaml"
  }
  module {
    source = "./modules/deploy_helm"
  }
}

run "test_example" {
  module {
      source  = "observeinc/collection/aws//modules/testing/exec"
      version = "2.9.0"
  }

   variables {
    command = "pytest ./scripts/test_example.py -v -s"
  }

  assert {
    condition     = output.error == ""
    error_message = "Error in Python Tests"
  }

}
