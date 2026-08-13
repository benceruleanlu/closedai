# Two identities with deliberately different jobs:
#
#   app-runtime      what the deployed container IS. Grants accumulate here
#                    only for what the app itself touches at runtime
#                    (secrets, Cloud SQL) — added in later commits alongside
#                    those resources.
#
#   github-deployer  what CI acts as during a deploy. It can push images and
#                    roll out new Cloud Run revisions, but it is not the app
#                    and cannot read the app's secrets.
#
# Keeping them separate means a compromised CI pipeline doesn't hold the
# production database credentials, and the running app can't push images.

resource "google_service_account" "runtime" {
  account_id   = "app-runtime"
  display_name = "Cloud Run runtime identity for the app"
}

resource "google_service_account" "deployer" {
  account_id   = "github-deployer"
  display_name = "GitHub Actions deploy identity"
}

# Deployer may push images to the registry.
resource "google_artifact_registry_repository_iam_member" "deployer_push" {
  repository = google_artifact_registry_repository.app.name
  location   = google_artifact_registry_repository.app.location
  role       = "roles/artifactregistry.writer"
  member     = "serviceAccount:${google_service_account.deployer.email}"
}

# Deployer may create/update Cloud Run services and revisions.
# run.developer (not run.admin): it cannot change who may invoke the
# service — that IAM stays owned by Terraform.
resource "google_project_iam_member" "deployer_run" {
  project = local.project_id
  role    = "roles/run.developer"
  member  = "serviceAccount:${google_service_account.deployer.email}"
}

# Deploying a service that runs AS app-runtime requires permission to
# "act as" that identity. Without this, anyone with deploy rights could
# quietly attach a more privileged service account to their container.
resource "google_service_account_iam_member" "deployer_acts_as_runtime" {
  service_account_id = google_service_account.runtime.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.deployer.email}"
}
