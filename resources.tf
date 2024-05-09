/*
Original work from Garret Wong

https://medium.com/google-cloud/a-hitchhikers-guide-to-gcp-service-account-impersonation-in-terraform-af98853ebd37
*/

/* Proxy Provider 

Defines a blank provider to retrieve access tokens via Service Account Impersonation
with seperate aliases to define duties by Service Account. This provider is termed
"tokengen", and its purpose to just for requesting access keys via Servie Impersonation.
*/
terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
      configuration_aliases = [
        google.tokengen,
      ]
    }
  }
}

## ---------------------------------------------------------------------------------------------------------------------
## GOOGLE PROJECT DATA SOURCE
## 
## GCP Project Configurations/Details Data Source.
## ---------------------------------------------------------------------------------------------------------------------
data "google_project" "this" {
  provider = google.tokengen
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

locals {
  cloud   = "gcp"
  program = "service-account"
  project = "cloud-auth"
}

locals {
  suffix = "${random_string.this.id}-${local.program}-${local.project}"
}

## ---------------------------------------------------------------------------------------------------------------------
## GOOGLE SERVICE ACCOUNT ACCESS TOKEN RESOURCE
##
## This data source retrieves an access token for the specified service account
## with rolesets already binded to create new service accounts.
##
## Parameters:
## - `target_service_account`: The email of the service account to impersonate.
## - `lifetime`: The duration for which the access token is valid.
## - `scopes`: The list of scopes for which the access token is requested.
## ---------------------------------------------------------------------------------------------------------------------
data "google_service_account_access_token" "impersonate" {
  provider = google.tokengen

  target_service_account = var.IMPERSONATE_SERVICE_ACCOUNT_EMAIL
  lifetime               = "600s"
  scopes = [
    "https://www.googleapis.com/auth/cloud-platform",
    "https://www.googleapis.com/auth/userinfo.email",
  ]
}


## ---------------------------------------------------------------------------------------------------------------------
## GOOGLE PROVIDER
##
## This provider configuration is used to authenticate with Google Cloud Platform using an access token retrieved from
## a service account.
##
## Parameters:
## - `access_token`: The access token retrieved from the service account.
## ---------------------------------------------------------------------------------------------------------------------
provider "google" {
  alias        = "creator"
  access_token = data.google_service_account_access_token.impersonate.access_token
  project      = data.google_project.this.project_id
}


## ---------------------------------------------------------------------------------------------------------------------
## GOOGLE SERVICE ACCOUNT RESOURCE
##
## This resource creates a new service account with no priviledges for later Project IAM role binding.
##
## Parameters:
## - `account_id`: The unique ID for the service account.
## - `display_name`: The display name for the service account.
## - `project`: The Google Cloud Platform project ID.
## ---------------------------------------------------------------------------------------------------------------------
resource "google_service_account" "this" {
  provider = google.creator

  account_id   = var.new_service_account_name
  display_name = "service-account-${local.suffix}"
  project      = data.google_project.this.project_id
}

## ---------------------------------------------------------------------------------------------------------------------
## GOOGLE SERVICE ACCOUNT IAM BINDING RESOURCE
##
## This resource grants a user the "iam.serviceAccountTokenCreator" role on a Google Cloud Platform service account.
## Bind the Service IAM Policy for token generator to the new Service Account
## with the impersonator user email as the Principal
##
## Parameters:
## - `service_account_id`: The unique ID for the service account.
## - `role`: The role to grant. In this case, "iam.serviceAccountTokenCreator".
## - `members`: The list of users or service accounts to which the role will be granted.
##
## Notes:
## - This resource is using the "google.creator" provider alias, which authenticates using an access token.
## ---------------------------------------------------------------------------------------------------------------------
resource "google_service_account_iam_binding" "this" {
  for_each = toset(var.impersonate_role_list)
  provider = google.creator

  service_account_id = google_service_account.this.name
  role               = each.value
  members            = ["serviceAccount:${var.IMPERSONATE_SERVICE_ACCOUNT_EMAIL}"]
}


## ---------------------------------------------------------------------------------------------------------------------
## GOOGLE PROJECT IAM MEMBER
##
## This resource assigns a role to a Google Cloud Platform service account at the project level.
##
## Parameters:
## - `project`: The ID of the Google Cloud Platform project.
## - `role`: The role to assign to the service account.
## - `member`: The email address of the service account.
## ---------------------------------------------------------------------------------------------------------------------
resource "google_project_iam_member" "this" {
  for_each = toset(var.roles_list)
  provider = google.creator

  project = data.google_project.this.project_id
  role    = each.value
  member  = google_service_account.this.member
}


## ---------------------------------------------------------------------------------------------------------------------
## TIME SLEEP FOR IAM PROPAGATION RESOURCE
##
## This resource adds a delay to allow IAM changes to propagate in Google Cloud Platform.
## No current mechanism to wait until Service IAM/Project IAM roles
## have been finished binding to Service Accounts and Principals. We
## wait for a minute to allow time for propogation to happen otherwise
## we're hit with 403 unauthorized errors
##
## Parameters:
## - `depends_on`: The resource or data source instances to wait for before creating this resource.
## - `create_duration`: The duration for which to wait before proceeding with the next steps.
## ---------------------------------------------------------------------------------------------------------------------
resource "time_sleep" "iam_propagation" {
  depends_on = [google_project_iam_member.this]

  create_duration = "60s"
}


## ---------------------------------------------------------------------------------------------------------------------
## GOOGLE SERVICE ACCOUNT ACCESS TOKEN DATA SOURCE
##
## This data source retrieves an access token for a Google service account to deploy project infra.
##
## Parameters:
## - `target_service_account`: The email address of the target service account for which to generate the access token.
## - `scopes`: The list of OAuth 2.0 scopes to include in the access token.
## ---------------------------------------------------------------------------------------------------------------------
data "google_service_account_access_token" "this" {
  provider   = google.creator
  depends_on = [time_sleep.iam_propagation]

  target_service_account = google_service_account.this.email
  scopes = [
    "https://www.googleapis.com/auth/cloud-platform",
  ]
}
