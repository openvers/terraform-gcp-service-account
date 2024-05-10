## ---------------------------------------------------------------------------------------------------------------------
## MODULE PARAMETERS
## These variables are expected to be passed in by the operator
## ---------------------------------------------------------------------------------------------------------------------

variable "IMPERSONATE_SERVICE_ACCOUNT_EMAIL" {
  type        = string
  description = <<EOT
    GCP Service Account Email equiped with sufficient Project IAM roles to create new Service Accounts.
    Please set using an ENV variable with TF_VAR_IMPERSONATE_SERVICE_ACCOUNT_EMAIL, and avoid hard coding
    in terraform.tfvars
  EOT
}

variable "new_service_account_name" {
  type        = string
  description = "New GCP Service Account to be created"
}

## ---------------------------------------------------------------------------------------------------------------------
## OPTIONAL PARAMETERS
## These variables have defaults and may be overridden
## ---------------------------------------------------------------------------------------------------------------------

variable "roles_list" {
  type        = list(string)
  description = "List of GCP IAM Roles to bind to the new Service Account"
  default = [
    "roles/iam.serviceAccountUser"
  ]
}

variable "impersonate_role_list" {
  type        = list(string)
  description = "List of GCP IAM Roles to bind to the Impersonating User"
  default = [
    "roles/iam.serviceAccountUser",
    "roles/iam.serviceAccountTokenCreator",
  ]
}