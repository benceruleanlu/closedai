# Workload Identity Federation: how GitHub Actions authenticates to GCP
# with no stored key.
#
# The old way was to export a service-account key file and save it as a
# GitHub secret — a permanent credential that never expires and leaks in
# logs. WIF replaces it with a trust relationship:
#
#   1. Every GitHub Actions job can mint a short-lived OIDC token, signed
#      by GitHub, stating which repo/branch/workflow it is.
#   2. The workload identity POOL below is told to trust GitHub's token
#      signer (the issuer_uri), but only for tokens whose claims satisfy
#      the attribute_condition — here, only this repository.
#   3. Google's STS endpoint exchanges that GitHub token for a short-lived
#      GCP token acting as the github-deployer service account.
#
# Nothing long-lived exists on either side; revoking access is deleting
# this trust, not rotating a leaked key.

locals {
  github_repository = "benceruleanlu/closedai"
}

resource "google_iam_workload_identity_pool" "github" {
  workload_identity_pool_id = "github"
  display_name              = "GitHub Actions"
}

resource "google_iam_workload_identity_pool_provider" "github" {
  workload_identity_pool_id          = google_iam_workload_identity_pool.github.workload_identity_pool_id
  workload_identity_pool_provider_id = "github-oidc"
  display_name                       = "GitHub OIDC"

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }

  # Which claims from GitHub's token become attributes on the GCP side.
  # google.subject is required; repository/ref let IAM bindings and
  # audit logs distinguish where a token came from.
  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.repository" = "assertion.repository"
    "attribute.ref"        = "assertion.ref"
  }

  # Hard gate: tokens from any other repository are rejected outright.
  attribute_condition = "assertion.repository == \"${local.github_repository}\""
}

# Tokens that clear the gate may impersonate the deployer service account.
# Tightening this to attribute.ref/refs/heads/main would restrict deploys
# to the main branch — worth doing once branch protection is in place.
resource "google_service_account_iam_member" "github_impersonates_deployer" {
  service_account_id = google_service_account.deployer.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github.name}/attribute.repository/${local.github_repository}"
}

# The two values the GitHub Actions workflow will need.
output "workload_identity_provider" {
  value       = google_iam_workload_identity_pool_provider.github.name
  description = "Passed to google-github-actions/auth as workload_identity_provider"
}

output "deployer_service_account" {
  value       = google_service_account.deployer.email
  description = "Passed to google-github-actions/auth as service_account"
}
