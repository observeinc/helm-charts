provider "helm" {
  kubernetes {
    config_path = pathexpand(var.cluster_config_path) #Needed by deploy_helm, uses current context
  }
}

provider "kubernetes" {
  config_path = pathexpand(var.cluster_config_path) #Needed by deploy_helm, uses current context 
}


module "setup_kind_cluster" {
  source                   = "./../setup_kind_cluster"
  kind_cluster_name        = "helm-charts-agent-test-cluster"
  kind_cluster_config_path = var.cluster_config_path
}


module "deploy_helm" {
  source          = "./../deploy_helm"
  observe_url     = var.observe_token
  observe_token   = var.observe_url
  values_file     = "default.yaml" #This is the default values file   
  use_local_chart = true

  helm_chart_agent_test_namespace="observe3"

  depends_on = [module.setup_kind_cluster]
}

