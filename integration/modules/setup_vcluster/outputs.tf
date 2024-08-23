output "manifest" {
  description = "The rendered manifest as JSON"
  value       = helm_release.my_vcluster.manifest
}

output "metadata" {
  description = "Status of the deployed release"
  value       = helm_release.my_vcluster.metadata
}

output "status" {
  description = "Status of the release"
  value       = helm_release.my_vcluster.status
}

output "vcluster_name" {
  value       = local.vcluster_name
  description = "Deployed vcluster name"
}