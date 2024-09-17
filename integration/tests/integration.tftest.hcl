# We have the ability to create variables specific for test and let it be controlled on a per test level
# For now, we'll let these variables be controlled either from tests.auto.tfvars or via TF_VAR variables
# See README.md

// variables {
//   cluster_config_path = "~/.kube/config" #Global var for provider
//   helm_chart_agent_test_namespace="observe"
//   helm_chart_agent_test_values_file="default.yaml"
// }

variables {
  cluster_config_path = "~/.kube/config" #Global var for provider

}

provider "helm" {
  kubernetes {
    config_path = pathexpand(var.cluster_config_path) #Needed by deploy_helm/setup_addnl_kubernetes, root level value
  }
}

provider "kubernetes" {
  config_path = pathexpand(var.cluster_config_path) #Needed by deploy_helm/setup_addnl_kubernetes, root level value
}


run "setup_kind_cluster" {
  variables {
    kind_cluster_config_path = var.cluster_config_path #Reference to root level values
  }
  module {
    source = "./modules/setup_kind_cluster"
  }
}

run "setup_addnl_kubernetes" {
  module {
    source = "./modules/setup_addnl_kubernetes"
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
    command = "pytest ./scripts/test_basic.py --tags ${run.deploy_helm.helm_chart_agent_test_values_file}"
    env_vars = {
      HELM_NAMESPACE = run.deploy_helm.helm_chart_agent_test_namespace
    }
  }

  assert {
    condition     = output.error == ""
    error_message = "Error in test_basic"
  }
}

run "test_logs" {
  module {
    source  = "observeinc/collection/aws//modules/testing/exec"
    version = "2.9.0"
  }

  variables {
    command = "pytest ./scripts/test_logs.py --tags ${run.deploy_helm.helm_chart_agent_test_values_file}"
    env_vars = {
      HELM_NAMESPACE = run.deploy_helm.helm_chart_agent_test_namespace
    }
  }

  assert {
    condition     = output.error == ""
    error_message = "Error in test_logs"
  }
}


run "test_nodes" {
  module {
    source  = "observeinc/collection/aws//modules/testing/exec"
    version = "2.9.0"
  }

  variables {
    command = "pytest ./scripts/test_nodes.py --tags ${run.deploy_helm.helm_chart_agent_test_values_file}"
    env_vars = {
      HELM_NAMESPACE = run.deploy_helm.helm_chart_agent_test_namespace
    }
  }

  assert {
    condition     = output.error == ""
    error_message = "Error in test_nodes"
  }
}
