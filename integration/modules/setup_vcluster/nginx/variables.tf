variable "region" {
  description = "The region to deploy helm chart in"
  type        = string
  default     = "us-west-2"
}

variable "cluster_role_arn" {
  description = "The role arn to assume to access the cluster to deploy helm chart"
  type        = string
  sensitive   = true
}