## ---------------------------------------------------------------------------------------------------------------------
## MODULE PARAMETERS
## These variables are expected to be passed in by the operator
## ---------------------------------------------------------------------------------------------------------------------

variable "project_number" {
  type        = string
  description = "GCP Project Number"
}

variable "pool_id" {
  type        = string
  description = "GCP Worflow Identity Federation Pool ID"
}

variable "provider_subject_assertion" {
  type        = list(string)
  description = "List of Provider IAM Member OIDC Token Subject Assertions"
}

variable "service_account_id" {
  type        = string
  description = "GCP Service Accoun ID to Impersonate with Identity Workflow Provider"
}

## ---------------------------------------------------------------------------------------------------------------------
## OPTIONAL PARAMETERS
## These variables have defaults and may be overridden
## ---------------------------------------------------------------------------------------------------------------------

variable "roles_list" {
  type        = list(string)
  description = "List of IAM Roles to bind to Principal Set Permissions"
  default = [
    "roles/iam.workloadIdentityUser"
  ]
}
