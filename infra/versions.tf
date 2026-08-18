# Terraform core and provider requirements, plus where state lives.
#
# The GCS backend stores the state file (Terraform's record of every
# resource it manages) in a versioned bucket so it survives any single
# machine and bad writes can be rolled back. The bucket itself is the
# one piece of infrastructure created outside Terraform, because it has
# to exist before Terraform can store anything:
#
#   gcloud storage buckets create gs://closedai-505222-tfstate \
#     --location=us-west1 --uniform-bucket-level-access \
#     --public-access-prevention
#   gcloud storage buckets update gs://closedai-505222-tfstate --versioning

terraform {
  required_version = ">= 1.9"

  backend "gcs" {
    bucket = "closedai-505222-tfstate"
    prefix = "terraform/state"
  }

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 7.44"
    }
  }
}
