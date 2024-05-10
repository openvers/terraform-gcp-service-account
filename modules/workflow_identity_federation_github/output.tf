output "workload_identity_pool_id" {
  description = "GCP Workload Identity Federartion Pool ID"
  value       = google_iam_workload_identity_pool.this.workload_identity_pool_id
}

output "workload_identity_provider_id" {
  description = "GCP Workload Idenitty Federation Provider ID"
  value       = google_iam_workload_identity_pool_provider.this.id
}