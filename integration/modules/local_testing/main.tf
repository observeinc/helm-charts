module "setup_kind_cluster" {
  source = "./../setup_kind_cluster"
}

module "deploy_helm" {
  source = "./../deploy_helm"
  cluster_config_path = module.setup_kind_cluster.kind_cluster_config_path
  observe_url = var.observe_token
  observe_token = var.observe_url
  values_file = "default.yaml" #This is the default values file 
}