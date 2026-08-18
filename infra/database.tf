# Cloud SQL Postgres — the one always-on, always-billed resource
# (db-f1-micro + 10GB SSD + backups ≈ $10–15/month).
#
# POSTGRES_17 matches compose.yaml locally so dev and prod never disagree
# about Postgres behavior.
#
# Connectivity model: the instance has a public IP but ZERO authorized
# networks, so no one can open a TCP connection to it directly. All access
# goes through Google's Cloud SQL connector layer, which authenticates the
# CALLER with IAM (roles/cloudsql.client) before any Postgres handshake
# happens. Cloud Run mounts the connection as a unix socket at
# /cloudsql/<connection_name>. Two locks on the door: IAM to reach the
# socket, then the ordinary Postgres password.
#
# The app's database USER and password are created out-of-band (like all
# secret values, they must not live in Terraform state):
#
#   gcloud sql users create app --instance=closedai --password=<random>
#
# and the full connection string goes into the database-url secret.

resource "google_sql_database_instance" "main" {
  name             = "closedai"
  database_version = "POSTGRES_17"
  region           = local.region

  # Refuses `terraform destroy` while true. Flip deliberately, never in
  # the same change that destroys.
  deletion_protection = true

  settings {
    edition           = "ENTERPRISE"
    tier              = "db-f1-micro" # shared-core, the smallest that exists
    availability_type = "ZONAL"       # REGIONAL doubles cost for HA we don't need yet
    disk_type         = "PD_SSD"
    disk_size         = 10
    disk_autoresize   = true

    backup_configuration {
      enabled                        = true
      start_time                     = "09:00" # UTC → 1–2am Pacific
      point_in_time_recovery_enabled = true    # replay to any moment in the last 7 days
    }

    ip_configuration {
      ipv4_enabled = true
      # No authorized_networks blocks: nothing connects without IAM.
    }
  }

  depends_on = [google_project_service.apis]
}

resource "google_sql_database" "app" {
  name     = "closedai"
  instance = google_sql_database_instance.main.name
}

# The runtime identity may open connections through the connector layer.
resource "google_project_iam_member" "runtime_sql_client" {
  project = local.project_id
  role    = "roles/cloudsql.client"
  member  = "serviceAccount:${google_service_account.runtime.email}"
}

# Cloud Run needs this exact string to mount the socket.
output "sql_connection_name" {
  value       = google_sql_database_instance.main.connection_name
  description = "project:region:instance identifier for connector mounts"
}
