terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
    }
  }

  backend "remote" {
    # The name of your Terraform Cloud organization.
    organization = "sim-parables"

    # The name of the Terraform Cloud workspace to store Terraform state files in.
    workspaces {
      name = "ci-cd-gcp-workspace"
    }
  }
}

data "google_project" "this" {
  provider = google.auth_session
}

locals {
  pool_id                          = "github-pool-${var.WIF_ID}"
  provider_id                      = "github-provider-${var.WIF_ID}"
  wif_provider_attribute_condition = "assertion.repository_owner == '${var.GITHUB_REPOSITORY_OWNER}'"

  principal_roles = [
    {
      principal = "principal://iam.googleapis.com/projects/${data.google_project.this.number}/locations/global/workloadIdentityPools/${local.pool_id}/subject/repo:${var.GITHUB_REPOSITORY}:ref:${var.GITHUB_REF}",
      role      = "roles/iam.workloadIdentityUser"
    },
    {
      principal = "principal://iam.googleapis.com/projects/${data.google_project.this.number}/locations/global/workloadIdentityPools/${local.pool_id}/subject/repo:${var.GITHUB_REPOSITORY}:environment:${var.GITHUB_ENV}",
      role      = "roles/iam.workloadIdentityUser"
    },
  ]
}

## ---------------------------------------------------------------------------------------------------------------------
## GCP PROVIDER
##
## Configures the GCP provider with OIDC Connect via ENV Variables.
## ---------------------------------------------------------------------------------------------------------------------
provider "google" {
  alias = "tokengen"
}

##---------------------------------------------------------------------------------------------------------------------
## GCP SERVICE ACCOUNT MODULE
##
## This module provisions a GCP service account along with associated roles and security groups.
##
## Parameters:
## - `IMPERSONATE_SERVICE_ACCOUNT_EMAIL`: Existing GCP service account email to impersonate for new SA creation.
## - `new_service_account_name`: New service account name.
##
## Providers:
## - `google.tokengen`: Alias for the GCP provider for generating service accounts.
##---------------------------------------------------------------------------------------------------------------------
module "gcp_service_account" {
  source = "../"

  IMPERSONATE_SERVICE_ACCOUNT_EMAIL = var.IMPERSONATE_SERVICE_ACCOUNT_EMAIL
  new_service_account_name          = var.new_service_account_name
  roles_list = [
    "roles/iam.serviceAccountUser",
    "roles/iam.serviceAccountAdmin",
    "roles/iam.workloadIdentityPoolAdmin"
  ]

  providers = {
    google.tokengen = google.tokengen
  }
}

## ---------------------------------------------------------------------------------------------------------------------
## GCP PROVIDER
##
## Configures the GCP provider the New Service Account Access Token.
## ---------------------------------------------------------------------------------------------------------------------
provider "google" {
  alias        = "auth_session"
  access_token = module.gcp_service_account.access_token
}

##---------------------------------------------------------------------------------------------------------------------
## GCP WORKLOAD IDENTITY FEDERATION MODULE
##
## This module provisions and configures a GCP Workload Identity Federation Pool & Provider to enable short lived
## authorization via OpenID Connect with trustred partner Github.
##
## Parameters:
## - `pool_id`: Given Workload Identity Federation Pool ID.
## - `provider_id`: Given Workload Identity Federation Provider ID.
## - `provider_attribute_condition`: CEL expression to validate token requests.
##
## Providers:
## - `google.tokengen`: Alias for the GCP provider for generating service accounts.
##---------------------------------------------------------------------------------------------------------------------
module "gcp_workload_identity_federation" {
  source     = "../modules/workflow_identity_federation_github"
  depends_on = [module.gcp_service_account]

  pool_id                      = local.pool_id
  provider_id                  = local.provider_id
  provider_attribute_condition = local.wif_provider_attribute_condition

  providers = {
    google.auth_session = google.auth_session
  }
}

##---------------------------------------------------------------------------------------------------------------------
## GCP WORKLOAD IDENTITY FEDERATION PRINCIPAL MODULE
##
## This module grants access to the GCP Workload Identity Federation Pool & Provider to a specific Service Account
## with defined role set permissions.
##
## Parameters:
## - `pool_id`: Given Workload Identity Federation Pool ID.
## - `service_account_id`: Service Account Email to Impersonate with Identity Workflow Provider
## - `provider_subject_assertion`: Token subject assertion for IAM Member Principal Set.
##
## Providers:
## - `google.tokengen`: Alias for the GCP provider for generating service accounts.
##---------------------------------------------------------------------------------------------------------------------
module "gcp_workload_identity_federation_principal" {
  source     = "../modules/workflow_identity_federation_principal"
  depends_on = [module.gcp_workload_identity_federation]

  project_number     = data.google_project.this.number
  pool_id            = module.gcp_workload_identity_federation.workload_identity_pool_id
  service_account_id = module.gcp_service_account.service_account_id
  principal_roles    = local.principal_roles

  providers = {
    google.auth_session = google.auth_session
  }
}