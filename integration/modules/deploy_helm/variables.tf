variable "region" {
  description = "The region to deploy helm chart in"
  type = string
  default = "us-west-2"
}

variable "cluster_role_arn" {
  description = "The role arn to assume to access the cluster to deploy helm chart"
  type = string
  sensitive = true
}

variable "OBSERVE_URL" {
  type        = string
  sensitive = true
  description = "Observe URL for agent helm-chart to send data to. Eg: https://<tenant_id>.collect.observe-staging.com/"
}

variable "OBSERVE_TOKEN" {
  type        = string
  sensitive = true
  description = "Observe Token for Datastream for agent helm-chart to send data to. Eg: ds1....23AB"
} 