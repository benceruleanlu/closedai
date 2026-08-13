locals {
  project_id = "closedai-505222"

  # us-west1 is deliberate: Cloud Run domain mappings are only offered in
  # ten regions, and this is the closest one of them. Cloud SQL and the
  # Artifact Registry repo will live here too; a region is effectively
  # permanent once Cloud SQL holds data, so it is a local, not a variable.
  region = "us-west1"
}

provider "google" {
  project = local.project_id
  region  = local.region
}

# Every Google Cloud API starts disabled in a new project and must be
# enabled before its resources can be created. serviceusage and
# cloudresourcemanager were enabled by hand during bootstrap (Terraform
# needs them to run at all); they are listed here anyway so the config
# documents the full set.
resource "google_project_service" "apis" {
  for_each = toset([
    "artifactregistry.googleapis.com", # stores the Docker images CI builds
    "cloudresourcemanager.googleapis.com",
    "iam.googleapis.com",            # service accounts
    "iamcredentials.googleapis.com", # lets GitHub's identity mint GCP tokens (WIF)
    "run.googleapis.com",            # Cloud Run itself
    "secretmanager.googleapis.com",  # runtime secrets for the app
    "serviceusage.googleapis.com",
    "sqladmin.googleapis.com", # Cloud SQL
    "sts.googleapis.com",      # token exchange endpoint used by WIF
  ])

  service = each.value

  # On `terraform destroy`, leave APIs enabled rather than yanking them
  # out from under any remaining resources.
  disable_on_destroy = false
}
