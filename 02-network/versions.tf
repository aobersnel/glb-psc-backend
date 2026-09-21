terraform {
  required_version = ">= 1.5.0"

  # Remote state backend:
  # Initialize with: terraform init -backend-config="bucket=<TFSTATE_BUCKET_NAME>"
  backend "gcs" {
    prefix = "psc-enlb-demo/02-network"
  }

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.0, < 9.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}
