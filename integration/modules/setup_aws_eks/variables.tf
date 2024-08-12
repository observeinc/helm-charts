variable "BASE_TAGS" {
  description = "base resource tags"
  type        = map(string)
  default = {
    owner        = "Observe"
    createdBy    = "terraform"
    team         = "Product Specialists "
    purpose      = "helm-charts/agent integration tests"
    git_repo_url = "https://github.com/observeinc/helm-charts/tree/main/charts/agent"
  }
}

variable "name_format" {
  description = "Common prefix for resource names"
  type        = string
  default     = "tf-helm-charts-agent-%s"
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}