
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