variable "cluster_config_path"{
  type = string
  default = "~/.kube/config"
  description = "Config Path to use for cluster where helm will be deployed"
}

variable "values_file" {
  type=string
  default = "default.yaml"
  description = "Values file to use to install helm chart"
}

variable "helm_chart_agent_test_namespace" {
  type = string
  default = "observe"  
  description = "namespace to use for agent helm chart"
}

variable "helm_chart_agent_test_release_name" {
  type = string
  default = "helm-chart-agent-test"  
  description = "release name to use for agent helm chart"
}

variable "observe_url" {
  type        = string
  sensitive   = true
  description = "Observe URL for agent helm-chart to send data to. Eg: https://<tenant_id>.collect.observe-staging.com/"
}

variable "observe_token" {
  type        = string
  sensitive   = true
  description = "Observe Token for Datastream for agent helm-chart to send data to. Eg: ds1....23AB"
} 