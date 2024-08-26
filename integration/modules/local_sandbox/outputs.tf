
output "kind_cluster_name" {
  description = "Kind cluster name"
  value       = module.setup_kind_cluster.kind_cluster_name
}

output "kind_cluster_config_path" {
  description = "Kind cluster config path" 
  value       = module.setup_kind_cluster.kind_cluster_config_path
}
output "helm_chart_agent_test_release_name" {
  description = "Helm_chart_agent_test_release_name"
  value       = module.deploy_helm.helm_chart_agent_test_release_name
}

output "helm_chart_agent_test_namespace" {
  description = "value of helm_chart_agent_test_namespace"
  value       = module.deploy_helm.helm_chart_agent_test_namespace
}

