variable "vcluster_prefix" {
  description = "Name of the vcluster to create"
  type        = string
  default = "tf-vcluster"
}


variable "region" {
  description = "The region where the host cluster exists"
  type        = string
  default     = "us-west-2"
}

variable "cluster_role_arn" {
  description = "The role arn to assume to access the cluster to deploy helm chart"
  type        = string
  sensitive   = true
}