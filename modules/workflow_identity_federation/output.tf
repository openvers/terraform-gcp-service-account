output "workload_identity_pool_id" {
  description = "GCP Workload Identity Federation Pool ID"
  value       = var.pool_id
}

output "workload_identity_provider_id" {
  description = "GCP Workload Identity Federation Provider ID"
  value       = google_iam_workload_identity_pool_provider.this.id
}
