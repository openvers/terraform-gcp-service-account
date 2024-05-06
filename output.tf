output "access_token" {
  description = "Authenticated Session with Service Account Key"
  value       = data.google_service_account_access_token.this.access_token
}

output "service_account_email" {
  description = "Authenticated Service Account Email"
  value       = google_service_account.this.email
}

output "service_account_member" {
  description = "Authenticated Service Account Member Details"
  value       = google_service_account.this.member
}

output "service_account_name" {
  description = "Authenticated Service Account Name"
  value       = google_service_account.this.name
}