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
  cloud   = "gcp"
  program = "wif"
  project = "cloud-auth"
}

## ---------------------------------------------------------------------------------------------------------------------
## RANDOM STRING RESOURCE
##
## This resource generates a random string of a specified length.
##
## Parameters:
## - `special`: Whether to include special characters in the random string.
## - `upper`: Whether to include uppercase letters in the random string.
## - `length`: The length of the random string.
## ---------------------------------------------------------------------------------------------------------------------
resource "random_string" "this" {
  special = false
  upper   = false
  length  = 4
}

## ---------------------------------------------------------------------------------------------------------------------
## GOOGLE IAM WORKLOAD IDENTITY POOL PROVIDER RESOURCE
##
## This resource will create a GCP Workload Identity Federation Pool Provider to configure attribute mappings and
## conditional expressions to identify which OIDC requests should receive short-term authorization.
## 
## > Soft Delete will allow this provider to remain 30 days after `terraform destroy`. Use random suffix to reduce
##   possible breakage.
## ---------------------------------------------------------------------------------------------------------------------
resource "google_iam_workload_identity_pool_provider" "this" {
  provider = google.auth_session

  workload_identity_pool_id          = var.pool_id
  workload_identity_pool_provider_id = "${substr(var.provider_id, 0, 27)}-${random_string.this.result}"
  display_name                       = substr(var.provider_name, 0, 32)
  description                        = var.provider_description
  disabled                           = false

  attribute_condition = var.provider_attribute_condition
  attribute_mapping   = var.provider_attribute_mapping

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

## ---------------------------------------------------------------------------------------------------------------------
## GOOGLE SERVICE ACCOUNT IAM MEMBER
##
## This resource assigns WIF principals roles on a GCP service account.
## ---------------------------------------------------------------------------------------------------------------------
resource "google_service_account_iam_member" "this" {
  provider = google.auth_session
  for_each = tomap({ for t in var.principal_roles : "${t.principal}-${t.role}" => t })

  service_account_id = var.service_account_id
  role               = each.value.role
  member             = each.value.principal
}
