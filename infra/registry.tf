# Where CI pushes the Docker images that Cloud Run runs.
# Images are addressed as:
#   us-west1-docker.pkg.dev/closedai-505222/app/<image>:<tag>
resource "google_artifact_registry_repository" "app" {
  repository_id = "app"
  location      = local.region
  format        = "DOCKER"
  description   = "Container images built by GitHub Actions"

  # Keep storage costs flat: untagged layers (superseded pushes) are
  # deleted after 30 days, and only the newest 10 tagged images are kept.
  cleanup_policies {
    id     = "delete-untagged"
    action = "DELETE"
    condition {
      tag_state  = "UNTAGGED"
      older_than = "2592000s" # 30 days
    }
  }
  cleanup_policies {
    id     = "keep-recent"
    action = "KEEP"
    most_recent_versions {
      keep_count = 10
    }
  }

  depends_on = [google_project_service.apis]
}
