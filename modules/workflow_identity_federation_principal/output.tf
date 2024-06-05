output "workload_identity_pool_id" {
  description = "GCP Workload Identity Federartion Pool ID"
  value       = "projects/${data.google_project.this.number}/locations/global/workloadIdentityPools/${var.pool_id}"
}

output "workload_identity_provider_id" {
  description = "GCP Workload Idenitty Federation Provider ID"
  value       = "projects/${data.google_project.this.number}/locations/global/workloadIdentityPools/${var.pool_id}/providers/${var.provider_id}"
}