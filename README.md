<p float="left">
  <img id="b-0" src="https://img.shields.io/badge/terraform-%235835CC.svg?style=for-the-badge&logo=terraform&logoColor=white" height="25px"/>
  <img id="b-1" src="https://img.shields.io/badge/Google_Cloud-4285F4?style=for-the-badge&logo=google-cloud&logoColor=white" height="25px"/>
  <img id="b-2" src="https://img.shields.io/github/actions/workflow/status/openvers/terraform-gcp-service-account/tf-integration-test.yml?style=flat&logo=github&label=CD%20(October%202026)" height="25px"/>
</p>

# Terraform GCP Service Account Module

## Overview

This repository provides a modular, production-ready Terraform implementation for provisioning Google Cloud service accounts and short-lived authentication workflows. It includes:

- Google Cloud service account creation
- Project IAM role bindings for the created service account
- Service account impersonation with short-lived access tokens
- GitHub Actions Workload Identity Federation pool and provider configuration
- Workload Identity Federation principal bindings for service account impersonation

The modules are designed for flexibility and can be used for both development and production environments without relying on long-lived service account keys.

## Module Structure

- Root module – Creates a Google Cloud service account, grants project IAM roles, grants impersonation roles, waits for IAM propagation, and emits a short-lived access token for downstream provider configuration.
- `modules/workflow_identity_federation/` – Creates a GitHub OIDC Workload Identity Federation pool/provider and grants Workload Identity Federation principals permission to impersonate the target service account.

---

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
## This module provisions a Google Cloud service account and grants project-level IAM roles.
##
## Parameters:
## - `IMPERSONATE_SERVICE_ACCOUNT_EMAIL`: Existing Google Cloud service account email to impersonate.
## - `new_service_account_name`: New service account account ID.
## - `roles_list`: Project IAM roles granted to the new service account.
##
## Providers:
## - `google.tokengen`: Alias for retrieving impersonated short-lived credentials.
##---------------------------------------------------------------------------------------------------------------------
module "gcp_service_account" {
  source = "../"

  IMPERSONATE_SERVICE_ACCOUNT_EMAIL = var.IMPERSONATE_SERVICE_ACCOUNT_EMAIL
  new_service_account_name          = var.new_service_account_name
  roles_list = [
    "roles/iam.serviceAccountUser",
    "roles/iam.serviceAccountAdmin",
    "roles/iam.workloadIdentityPoolAdmin",
  ]

  providers = {
    google.tokengen = google.tokengen
  }
}

## ---------------------------------------------------------------------------------------------------------------------
## GCP PROVIDER
##
## Configures a Google provider session using the short-lived access token emitted by the service account module.
## ---------------------------------------------------------------------------------------------------------------------
provider "google" {
  alias        = "auth_session"
  access_token = module.gcp_service_account.access_token
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
      principal = "principal://iam.googleapis.com/projects/${data.google_project.this.number}/locations/global/workloadIdentityPools/${local.pool_id}/subject/repo:${var.GITHUB_REPOSITORY}:ref:${var.GITHUB_REF}"
      role      = "roles/iam.workloadIdentityUser"
    },
    {
      principal = "principal://iam.googleapis.com/projects/${data.google_project.this.number}/locations/global/workloadIdentityPools/${local.pool_id}/subject/repo:${var.GITHUB_REPOSITORY}:environment:${var.GITHUB_ENV}"
      role      = "roles/iam.workloadIdentityUser"
    },
  ]
}

##---------------------------------------------------------------------------------------------------------------------
## GCP WORKLOAD IDENTITY FEDERATION MODULE
##
## This module creates a Workload Identity Federation pool and GitHub OIDC provider, then grants
## GitHub OIDC principals permission to impersonate the target service account.
##---------------------------------------------------------------------------------------------------------------------
module "gcp_workload_identity_federation" {
  source     = "../modules/workflow_identity_federation"
  depends_on = [module.gcp_service_account]

  pool_id                      = local.pool_id
  provider_id                  = local.provider_id
  provider_attribute_condition = local.wif_provider_attribute_condition
  service_account_id = module.gcp_service_account.service_account_id
  principal_roles    = local.principal_roles

  providers = {
    google.auth_session = google.auth_session
  }
}

```

## Testing

A test harness is provided in the `test/` directory. It includes:

- Service account provisioning through impersonated Google provider sessions
- GitHub Workload Identity Federation pool and provider setup
- Principal bindings for GitHub OIDC subjects and environments
- Output values for integration with CI/CD pipelines

Validate GitHub Workflows locally with [Nekto's Act](https://nektosact.com/introduction.html). More info can be found in the GitHub repository: [https://github.com/nektos/act](https://github.com/nektos/act).

### Prerequisites

Before running Terraform, configure a bootstrap Google Cloud service account that can create the service account and IAM resources managed by this module.


```bash
#[TODO] Provide documentation to GCP IAM Configuration

cat << 'EOF' > ~/creds/gcp.secrets.envrc
export GOOGLE_IMPERSONATE_SERVICE_ACCOUNT_EMAIL="<service-account-email>"
export GOOGLE_WORKLOAD_IDENTITY_PROVIDER="<identity-provider-uri>"
export GOOGLE_WORKLOAD_IDENTITY_PROVIDER_ID="<identity-provider-resource-id>"
export GOOGLE_WORKLOAD_IDENTITY_POOL_ID="<identity-pool-id>"

export GOOGLE_OAUTH_ACCESS_TOKEN="$(
  gcloud auth application-default print-access-token \
    --impersonate-service-account="$GOOGLE_SERVICE_ACCOUNT_EMAIL
)"

export TF_API_TOKEN=$(cat ~/.terraform.d/credentials.tfrc.json | jq -r '.credentials."app.terraform.io".token')
EOF
```

### Local Deployment Testing

```bash
gcloud auth application-default login \
  --impersonate-service-account="$GOOGLE_IMPERSONATE_SERVICE_ACCOUNT_EMAIL"

terraform login app.terraform.io

terraform -chdir=test init
terraform -chdir=test plan
terraform -chdir=test apply -auto-approve
terraform -chdir=test destroy -auto-approve
```

### Manual Dispatch Testing

```bash
# Try the Terraform Read/Plan job first once the workflow is available.
act -j terraform-dispatch-plan \
  -e .github/local.json \
  -s GOOGLE_PROJECT \
  -s GOOGLE_IMPERSONATE_SERVICE_ACCOUNT_EMAIL \
  -s GOOGLE_OAUTH_ACCESS_TOKEN \
  -s GOOGLE_WORKLOAD_IDENTITY_PROVIDER \
  -s GOOGLE_WORKLOAD_IDENTITY_POOL_ID \
  -s TF_API_TOKEN \
  --remote-name $(git remote show)

act -j terraform-dispatch-apply \
  -e .github/local.json \
  -s GOOGLE_PROJECT \
  -s GOOGLE_IMPERSONATE_SERVICE_ACCOUNT_EMAIL \
  -s GOOGLE_OAUTH_ACCESS_TOKEN \
  -s GOOGLE_WORKLOAD_IDENTITY_PROVIDER \
  -s GOOGLE_WORKLOAD_IDENTITY_POOL_ID \
  -s TF_API_TOKEN \
  --remote-name $(git remote show)

act -j terraform-dispatch-destroy \
  -e .github/local.json \
  -s GOOGLE_PROJECT \
  -s GOOGLE_IMPERSONATE_SERVICE_ACCOUNT_EMAIL \
  -s GOOGLE_OAUTH_ACCESS_TOKEN \
  -s GOOGLE_WORKLOAD_IDENTITY_PROVIDER \
  -s GOOGLE_WORKLOAD_IDENTITY_POOL_ID \
  -s TF_API_TOKEN \
  --remote-name $(git remote show)
```

### Integration Testing

Integration workflow support will be added with the GitHub workflow definitions. Once available, use `act` to validate the full integration lifecycle locally.

```bash
# Create an artifact location to upload/download between steps locally.
mkdir /tmp/artifacts

# Run the full integration test once the workflow is available.
act -j terraform-integration-destroy \
  -e .github/local.json \
  -s GOOGLE_PROJECT \
  -s GOOGLE_IMPERSONATE_SERVICE_ACCOUNT_EMAIL \
  -s GOOGLE_OAUTH_ACCESS_TOKEN \
  -s GOOGLE_WORKLOAD_IDENTITY_PROVIDER \
  -s GOOGLE_WORKLOAD_IDENTITY_POOL_ID \
  -s TF_API_TOKEN \
  --remote-name $(git remote show) \
  --artifact-server-path /tmp/artifacts
```

### Unit Tests

Unit workflow support will be added with the GitHub workflow definitions. Once available, use `act` to run Terraform formatting, validation, and unit-style checks locally.

```bash
act -j terraform-unit-tests \
  -e .github/local.json \
  -s GOOGLE_PROJECT \
  -s GOOGLE_REGION \
  -s TF_API_TOKEN \
  --remote-name $(git remote show)
```

---

## License

See [LICENSE](./LICENSE) for details.
