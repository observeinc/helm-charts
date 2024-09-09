variables {
  cluster_config_path = "~/.kube/config" #Global var for provider 
  pytest_tag=replace(var.values_file, ".yaml", "")  #Global var for pytest 
}

provider "helm" {
  kubernetes {
    config_path = pathexpand(var.cluster_config_path) #Needed by deploy_helm, root level value 
  }
}

provider "kubernetes" {
  config_path = pathexpand(var.cluster_config_path) #Needed by deploy_helm, root level value 
}


run "setup_kind_cluster" {
  variables {
    kind_cluster_config_path = var.cluster_config_path #Reference to root level values 
  }
  module {
    source = "./modules/setup_kind_cluster"
  }
}

run "deploy_helm" {
  module {
    source = "./modules/deploy_helm"
  }
}


run "test_basic" {
  module {
    source  = "observeinc/collection/aws//modules/testing/exec"
    version = "2.9.0"
  }

  variables {
    command = "pytest ./scripts/test_basic.py -s -v --tags ${var.pytest_tag}"
    env_vars = {
      HELM_NAMESPACE = run.deploy_helm.helm_chart_agent_test_namespace
    }
  }

  assert {
    condition     = output.error == ""
    error_message = "Error in Python Tests"
  }

}
