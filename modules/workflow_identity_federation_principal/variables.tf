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

variable "principal_roles" {
  description = "List of WIF Principal Member to Role mappings"
  type        = list(object({
    principal = string,
    role = string
  }))
}

variable "service_account_id" {
  type        = string
  description = "GCP Service Accoun ID to Impersonate with Identity Workflow Provider"
}

## ---------------------------------------------------------------------------------------------------------------------
## OPTIONAL PARAMETERS
## These variables have defaults and may be overridden
## ---------------------------------------------------------------------------------------------------------------------

