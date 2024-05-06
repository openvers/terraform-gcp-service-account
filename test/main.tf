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
  roles_list                        = var.roles_list

  providers = {
    google.tokengen = google.tokengen
  }
}