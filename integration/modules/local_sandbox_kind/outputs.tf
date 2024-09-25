
output "kind_cluster_name" {
  description = "Kind cluster name"
  value       = module.setup_kind_cluster.kind_cluster_name
}

output "kind_cluster_config_path" {
  description = "Kind cluster config path"
  value       = module.setup_kind_cluster.kind_cluster_config_path
}

output "kind_cluster_endpoint" {
  description = "Kind Cluster Endpoint"
  value       = module.setup_kind_cluster.kind_cluster_endpoint
}
output "helm_chart_agent_test_release_name" {
  description = "Helm_chart_agent_test_release_name"
  value       = var.deploy_helm_enabled ? module.deploy_helm[0].helm_chart_agent_test_release_name : null
}

output "helm_chart_agent_test_namespace" {
  description = "value of helm_chart_agent_test_namespace"
  value       = var.deploy_helm_enabled ? module.deploy_helm[0].helm_chart_agent_test_namespace : null
}

output "helm_chart_agent_test_values_file" {
  description = "Which values file was used for deployment"
  value       = var.deploy_helm_enabled ? module.deploy_helm[0].helm_chart_agent_test_values_file : null
}

output "node-details" {
  value = module.setup_addnl_kubernetes.node-details

}
