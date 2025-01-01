<p float="left">
  <img id="b-0" src="https://img.shields.io/badge/terraform-%235835CC.svg?style=for-the-badge&logo=terraform&logoColor=white" height="25px"/>
  <img id="b-1" src="https://img.shields.io/badge/Google_Cloud-4285F4?style=for-the-badge&logo=google-cloud&logoColor=white" height="25px"/>
  <img id="b-2" src="https://img.shields.io/github/actions/workflow/status/sim-parables/terraform-gcp-service-account/tf-integration-test.yml?style=flat&logo=github&label=CD%20(January%202025)" height="25px"/>
</p>

# Terraform GCP Service Account

A reusable module for creating Service Accoounts with limited privileges for both Development and Production purposes.

## Usage

```hcl
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

```

## Inputs

| Name                              | Description                       | Type         | Default | Required |
|:----------------------------------|:----------------------------------|:-------------|:--------|:---------|
| impersonate_service_account_email | Existing Service Account Email    | string       | N/A     | Yes      |
| new_service_account_name          | New Service Account Name          | String       | {}      | No       |
| roles_list                        | GCP IAM Roles                     | list         | []      | No       |

## Outputs

| Name                   | Description                            |
|:-----------------------|:---------------------------------------|
| access_token           | GCP Service Account Secret             |
| service_account_email  | New GCP Service Account Email          |
| service_account_member | New GCP Service Account Member Details |
| service_account_name   | New GCP Service Account Name           |
