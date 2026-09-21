terraform {
  required_version = ">= 1.5.0"

  backend "gcs" {
    prefix = "psc-enlb-demo/06-client-vpc"
  }

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.30.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}
