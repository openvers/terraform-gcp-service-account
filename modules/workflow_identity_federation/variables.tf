## ---------------------------------------------------------------------------------------------------------------------
## MODULE PARAMETERS
## These variables are expected to be passed in by the operator
## ---------------------------------------------------------------------------------------------------------------------

variable "pool_id" {
  type        = string
  description = "Existing GCP Workflow Identity Federation Pool ID"
}

variable "provider_id" {
  type        = string
  description = "GCP Workflow Identity Federation Pool Provider ID"
}

variable "provider_attribute_condition" {
  type        = string
  description = <<EOT
    GCP Workflow Identity Federation Pool Provider Condition CEL Expression.
    https://cloud.google.com/iam/help/workload-identity/conditions
    EOT
}

variable "principal_roles" {
  description = "List of WIF principal member to role mappings"
  type = list(object({
    principal = string,
    role      = string
  }))
}

variable "service_account_id" {
  type        = string
  description = "GCP Service Account ID to impersonate with the Workload Identity Federation provider"
}

## ---------------------------------------------------------------------------------------------------------------------
## OPTIONAL PARAMETERS
## These variables have defaults and may be overridden
## ---------------------------------------------------------------------------------------------------------------------

variable "provider_name" {
  type        = string
  description = "GCP Workflow Identity Federation Pool Provider display name"
  default     = "Example Workflow Identity Pool Provider"
}

variable "provider_description" {
  type        = string
  description = "GCP Workflow Identity Federation Pool Provider description"
  default     = "Example GCP Workflow Identity Pool Provider to enable Open ID Connect authentication with recognized OIDC partners"
}

variable "provider_attribute_mapping" {
  description = "GCP Workflow Identity Federation Pool Provider attribute mappings"
  type        = map(string)
  default = {
    "google.subject"             = "assertion.sub",
    "attribute.actor"            = "assertion.actor",
    "attribute.repository"       = "assertion.repository",
    "attribute.repository_owner" = "assertion.repository_owner"
  }
}
