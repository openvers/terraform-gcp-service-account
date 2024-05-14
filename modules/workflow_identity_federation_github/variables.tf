## ---------------------------------------------------------------------------------------------------------------------
## MODULE PARAMETERS
## These variables are expected to be passed in by the operator
## ---------------------------------------------------------------------------------------------------------------------

variable "pool_id" {
  type        = string
  description = "GCP Worflow Identity Federation Pool ID"
}

variable "provider_id" {
  type        = string
  description = "GCP Worflow Identity Federation Pool Provider ID"
}

variable "provider_attribute_condition" {
  type        = string
  description = <<EOT
    GCP Worflow Identity Federation Pool Provider Condition CEL Expression.
    https://cloud.google.com/iam/help/workload-identity/conditions
    EOT
}

## ---------------------------------------------------------------------------------------------------------------------
## OPTIONAL PARAMETERS
## These variables have defaults and may be overridden
## ---------------------------------------------------------------------------------------------------------------------

variable "pool_name" {
  type        = string
  description = "GCP Worflow Identity Federation Pool Display Name"
  default     = "Example Workflow Identity Pool"
}

variable "pool_description" {
  type        = string
  description = "GCP Worflow Identity Federation Pool Display Name"
  default     = "Example GCP Workflow Identity Pool to enable Open ID Connect authentication with reconginzed OIDC partners"
}

variable "provider_name" {
  type        = string
  description = "GCP Worflow Identity Federation Pool Display Name"
  default     = "Example Workflow Identity Pool Provider"
}

variable "provider_description" {
  type        = string
  description = "GCP Worflow Identity Federation Pool Display Name"
  default     = "Example GCP Workflow Identity Pool Provider to enable Open ID Connect authentication with reconginzed OIDC partners"
}

variable "provider_attribute_mapping" {
  description = "GCP Worflow Identity Federation Pool Provider Attribute Mappings"
  type        = map(string)
  default = {
    "google.subject"             = "assertion.sub",
    "attribute.actor"            = "assertion.actor",
    "attribute.repository"       = "assertion.repository",
    "attribute.repository_owner" = "assertion.repository_owner"
  }
}
