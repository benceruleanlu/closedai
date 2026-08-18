# Secret Manager holds the values; Terraform only creates the CONTAINERS.
#
# Values are added out-of-band so they never pass through Terraform state
# (state is plaintext to anyone who can read the bucket):
#
#   printf '%s' "<value>" | gcloud secrets versions add <name> --data-file=-
#
# The app reads these as env vars mounted by the Cloud Run service.
# Non-sensitive config (BETTER_AUTH_URL, DATABASE_POOL_MAX) stays as plain
# env vars on the service, not here — secrecy is the only reason to pay
# the indirection cost.

resource "google_secret_manager_secret" "app" {
  for_each = toset([
    "better-auth-secret",   # session cookie signing key
    "google-client-secret", # OAuth client secret from the consent screen
    "database-url",         # includes the database password
  ])

  secret_id = each.value

  replication {
    auto {}
  }

  depends_on = [google_project_service.apis]
}

# Only the runtime identity may read secret values. Note the deployer is
# absent: CI rolls out revisions that REFERENCE these secrets, but can
# never read them.
resource "google_secret_manager_secret_iam_member" "runtime_reads" {
  for_each = google_secret_manager_secret.app

  secret_id = each.value.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.runtime.email}"
}
