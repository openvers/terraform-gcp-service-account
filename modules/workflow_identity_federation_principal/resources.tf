terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
      configuration_aliases = [
        google.auth_session,
      ]
    }
  }
}

## ---------------------------------------------------------------------------------------------------------------------
## GOOGLE SERVICE ACCOUNT IAM MEMBER
##
## This resource assigns a role to a GCP service account at the IAM Member level.
##
## Parameters:
## - `service_account_id`: Service Account ID.
## - `principal_roles`: The list of Principal/Role mappings to assign to the service account.
## ---------------------------------------------------------------------------------------------------------------------
resource "google_service_account_iam_member" "this" {
  provider = google.auth_session
  for_each = tomap({ for t in var.principal_roles : "${t.principal}-${t.role}" => t })

  service_account_id = var.service_account_id
  role               = each.value.role
  member             = each.value.principal
}