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

locals {
  member_roles = distinct([
    for pair in setproduct(var.provider_subject_assertion, var.roles_list) :
    {
      principal = coalesce(
        "principal://iam.googleapis.com/projects/${var.project_number}",
        "/locations/global/workloadIdentityPools/${var.pool_id}",
        "/subject/${pair[0]}"
      ),
      role = pair[1]
    }
  ])
}

## ---------------------------------------------------------------------------------------------------------------------
## GOOGLE SERVICE ACCOUNT IAM MEMBER
##
## This resource assigns a role to a GCP service account at the IAM Member level.
##
## Parameters:
## - `service_account_id`: Service Account ID.
## - `role`: The role to assign to the service account.
## - `member`: The Workflow Identity Federation Provider Member ID and token subject assertion.
## ---------------------------------------------------------------------------------------------------------------------
resource "google_service_account_iam_member" "this" {
  provider = google.auth_session
  for_each = tomap({ for t in local.member_roles : "${t.principal}-${t.role}" => t })

  service_account_id = var.service_account_id
  role               = each.value.role
  member             = each.value.principal
}