# Helm and Kubernetes provider must be instantiated AFTER kind cluster is created
# See warning: https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs#stacking-with-managed-kubernetes-cluster-resources

provider "helm" {
  kubernetes {
    config_path = pathexpand(var.cluster_config_path) #Needed by deploy_helm, uses current context
    host    = module.setup_kind_cluster.kind_cluster_endpoint
  }
}

provider "kubernetes" {
  config_path = pathexpand(var.cluster_config_path) #Needed by deploy_helm, uses current context
  host    = module.setup_kind_cluster.kind_cluster_endpoint
}


module "setup_kind_cluster" {
  source                   = "./../setup_kind_cluster"
  kind_cluster_name        = "helm-charts-agent-test-cluster"
  kind_cluster_config_path = var.cluster_config_path
}

module "setup_addnl_kubernetes" {

  source = "./../setup_addnl_kubernetes"
  helm_chart_agent_test_values_file = var.helm_chart_agent_test_values_file

  depends_on = [ module.setup_kind_cluster ]
}


module "deploy_helm" {
  source                            = "./../deploy_helm"
  observe_url                       = var.observe_url
  observe_token                     = var.observe_token
  helm_chart_agent_test_values_file = var.helm_chart_agent_test_values_file
  helm_chart_agent_test_namespace   = var.helm_chart_agent_test_namespace
  use_local_chart                   = true

  depends_on = [module.setup_addnl_kubernetes]
  count = var.deploy_helm_enabled ? 1 : 0
}
