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
## GOOGLE IAM WORKLOAD IDENTITY POOL RESOURCE
##
## This resource will create a GCP Workload Identity Federation Pool to allow for short-lived authorization
## without the need for Service Account credentials through Open ID Connect with trusted partners like Github.
##
## Parameters:
## - `workload_identity_pool_id`: Given Workload Identity Federation Pool ID.
## - `display_name`: Workload Identity Federation Pool Name.
## - `description`: Brief pool description.
## - `disabled`: Boolean flag to indicate if the pool should be enabled/disabled on creation.
## ---------------------------------------------------------------------------------------------------------------------
resource "google_iam_workload_identity_pool" "this" {
  provider = google.auth_session

  workload_identity_pool_id = substr(var.pool_id, 0, 32)
  display_name              = substr(var.pool_name, 0, 32)
  description               = var.pool_description
  disabled                  = false
}

## ---------------------------------------------------------------------------------------------------------------------
## GOOGLE IAM WORKLOAD IDENTITY POOL PROVIDER RESOURCE
##
## This resource will create a GCP Workload Identity Federation Pool Provider to configure attribute mappings and
## conditional expressions to identify which OIDC requests should receive short-term authorization.
##
## Parameters:
## - `workload_identity_pool_id`: Workload Identity Federation Pool ID.
## - `workload_identity_pool_provider_id`: Given Workload Identity Federation Provider ID.
## - `display_name`: Workload Identity Federation Provider Name.
## - `description`: Brief provider description.
## - `disabled`: Boolean flag to indicate if the pool should be enabled/disabled on creation.
## - `attribute_condition`: CEL expression to validate token requests.
## - `attribute_mapping`: Custom attribute mappings from GCP WIF attributes to Github Attributes.
## ---------------------------------------------------------------------------------------------------------------------
resource "google_iam_workload_identity_pool_provider" "this" {
  provider = google.auth_session

  workload_identity_pool_id          = google_iam_workload_identity_pool.this.workload_identity_pool_id
  workload_identity_pool_provider_id = substr(var.provider_id, 0, 32)
  display_name                       = substr(var.provider_name, 0, 32)
  description                        = var.provider_description
  disabled                           = false

  attribute_condition = var.provider_attribute_condition
  attribute_mapping   = var.provider_attribute_mapping

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}