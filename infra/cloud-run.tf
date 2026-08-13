# The Cloud Run service — the ownership boundary lives here.
#
# Terraform owns the PLATFORM: resources, scaling, identity, env wiring,
# secret mounts, who may invoke. CI owns exactly one field: which image is
# running. The lifecycle block below makes Terraform ignore the image (and
# the client fields gcloud stamps on deploy), so `gcloud run deploy
# --image=...` from GitHub Actions never fights this config.
#
# The service starts on Google's public "hello" image; the first CI deploy
# replaces it with the real app.

locals {
  # Cloud Run URLs are deterministic: SERVICE-PROJECTNUMBER.REGION.run.app.
  # Better Auth needs its public origin at boot, and this stays correct
  # until a custom domain replaces it.
  service_url = "https://closedai-119435485881.${local.region}.run.app"
}

resource "google_cloud_run_v2_service" "app" {
  name     = "closedai"
  location = local.region

  template {
    service_account = google_service_account.runtime.email

    scaling {
      min_instance_count = 0 # scale to zero: pay nothing while idle, accept cold starts
      max_instance_count = 3 # denial-of-wallet cap: bursty traffic can't run up a bill
    }

    volumes {
      name = "cloudsql"
      cloud_sql_instance {
        instances = [google_sql_database_instance.main.connection_name]
      }
    }

    containers {
      image = "us-docker.pkg.dev/cloudrun/container/hello"

      resources {
        limits = {
          cpu    = "1"
          memory = "512Mi"
        }
      }

      volume_mounts {
        name       = "cloudsql"
        mount_path = "/cloudsql"
      }

      # Plain configuration: not secret, so visible in the console and in
      # `terraform plan` diffs, which is what you want for debugging.
      env {
        name  = "BETTER_AUTH_URL"
        value = local.service_url
      }
      env {
        name  = "DATABASE_POOL_MAX"
        value = "5"
      }
      env {
        # OAuth client IDs are public identifiers, not secrets.
        # Placeholder until the OAuth consent screen exists.
        name  = "GOOGLE_CLIENT_ID"
        value = "placeholder-until-oauth-configured"
      }

      # Secret-backed env vars: Cloud Run reads the value from Secret
      # Manager at instance start using the RUNTIME service account.
      # "latest" is resolved per revision, so rotating a secret takes
      # effect on the next deploy, not instantly.
      dynamic "env" {
        for_each = {
          BETTER_AUTH_SECRET   = "better-auth-secret"
          DATABASE_URL         = "database-url"
          GOOGLE_CLIENT_SECRET = "google-client-secret"
        }
        content {
          name = env.key
          value_source {
            secret_key_ref {
              secret  = env.value
              version = "latest"
            }
          }
        }
      }
    }
  }

  lifecycle {
    ignore_changes = [
      template[0].containers[0].image, # CI owns the image
      client,                          # gcloud stamps these on every deploy
      client_version,
    ]
  }

  depends_on = [
    google_secret_manager_secret_iam_member.runtime_reads,
    google_project_iam_member.runtime_sql_client,
  ]
}

# Anyone on the internet may SEND REQUESTS to the service. This is a web
# app: authentication happens inside it (Better Auth), not at the platform
# layer. Without this binding Cloud Run would demand a Google-signed IAM
# token on every request — right default for internal services, wrong for
# a public sign-in page.
resource "google_cloud_run_v2_service_iam_member" "public_invoker" {
  name     = google_cloud_run_v2_service.app.name
  location = google_cloud_run_v2_service.app.location
  role     = "roles/run.invoker"
  member   = "allUsers"
}

output "service_url" {
  value       = google_cloud_run_v2_service.app.uri
  description = "The service's run.app URL"
}
