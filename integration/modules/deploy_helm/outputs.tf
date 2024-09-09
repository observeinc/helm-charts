output "manifest" {
  description = "The rendered manifest as JSON"
  value       = helm_release.observe-agent.manifest
}

output "metadata" {
  description = "Status of the deployed release"
  value       = helm_release.observe-agent.metadata
}

output "status" {
  description = "Status of the release"
  value       = helm_release.observe-agent.status
}

output "helm_chart_agent_test_release_name" {
  description = "Helm_chart_agent_test_release_name"
  value       = helm_release.observe-agent.metadata[0].name
}

output "helm_chart_agent_test_namespace" {
  description = "value of helm_chart_agent_test_namespace"
  value       = helm_release.observe-agent.metadata[0].namespace
}

output "helm_chart_agent_test_values_file" {
  description = "Which values file was used"
  value       = var.helm_chart_agent_test_values_file
}
