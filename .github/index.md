# Github Action Workflows

[Github Actions](https://docs.github.com/en/actions) to automate, customize, and execute your software development workflows coupled with the repository.

## Local Actions

Validate Github Workflows locally with [Nekto's Act](https://nektosact.com/introduction.html). More info found in the Github Repo [https://github.com/nektos/act](https://github.com/nektos/act).

### Prerequisits

Store the identical Secrets in Github Organization/Repository to local workstation

```
cat <<EOF > ~/creds/gcp.secrets
# Terraform.io Token
TF_API_TOKEN_AWS_WORKSPACE=...

# Github PAT
GITHUB_TOKEN=...

# GCP
GCP_PROJECT=...
GOOGLE_OAUTH_ACCESS_TOKEN=...
GCP_IMPERSONATE_SERVICE_ACCOUNT_EMAIL=...
GCP_WORKLOAD_IDENTITY_PROVIDER=...
EOF
```

### Refreshing local auth token
Local account impersonation authentication tokens only have a lifetime of 60 minutes.
Refresh often:

```
sed -i -E "s/(GOOGLE_OAUTH_ACCESS_TOKEN\=).*/\1$(gcloud auth print-access-token)/" ~/creds/gcp.secrets
```

### Manual Dispatch Testing

```
# Try the Terraform Read job first
act -j terraform-dispatch-read \
    -e .github/local.json \
    --secret-file ~/creds/gcp.secrets \
    --remote-name $(git remote show)

# Use the Terraform Write job to apply/destroy the infra configuration
act -j terraform-dispatch-write \
    -e .github/local.json \
    --secret-file ~/creds/gcp.secrets \
    --remote-name $(git remote show)
```

### Integration Testing

```
# Create an artifact location to upload/download between steps locally
mkdir /tmp/artifacts

# Run the full Integration test with
act -j terraform-integration-destroy \
    -e .github/local.json \
    --secret-file ~/creds/gcp.secrets \
    --remote-name $(git remote show) \ 
    --artifact-server-path /tmp/artifacts
```

### Unit Testing

```
act -j terraform-unit-tests \
    -e .github/local.json \
    --secret-file ~/creds/gcp.secrets \
    --remote-name $(git remote show)
```