
output "kind_cluster_name" {
  value       = var.kind_cluster_name
  description = "Name of kind cluster"
}

output "kind_cluster_kubeconfig" {
  value       = kind_cluster.cluster.kubeconfig
  description = "The kubeconfig for the cluster after it is created"
  sensitive   = true
}

output "kind_cluster_endpoint" {
  value       = kind_cluster.cluster.endpoint
  description = " Kubernetes APIServer endpoint."
}

output "kind_cluster_config_path" {
  value       = var.kind_cluster_config_path
  description = "The location where this cluster's kubeconfig was saved to."
}

