
run "setup_vcluster" {
  module {
    source = "./modules/setup_kind_cluster"
  }
}

run "deploy_helm" {
  module {
    source = "./modules/deploy_helm"
  }
}


