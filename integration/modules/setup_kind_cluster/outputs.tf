
output "kubeconfig" {
  value = kind_cluster.cluster.kubeconfig
  description = "The kubeconfig for the cluster after it is created"
}

output "endpoint" {
  value = kind_cluster.cluster.endpoint
  description = " Kubernetes APIServer endpoint."
}


