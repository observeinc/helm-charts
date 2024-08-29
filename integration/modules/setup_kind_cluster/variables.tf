variable "kind_cluster_name" {
  type        = string
  description = "The name of the cluster."
  default     = "helm-charts-agent-test-cluster"
}

variable "kind_cluster_config_path" {
  type        = string
  description = "The location where this cluster's kubeconfig will be saved to."
  default     = "~/.kube/config"
}
