terraform {
  required_version = ">= 1.5.0"

  # 01-project uses local state permanently.
  # It creates the GCP project and the GCS bucket (<project_id>-tfstate)
  # used as the remote "gcs" backend by all higher layers (02-network through 06-client-vpc).
  backend "local" {}

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.0, < 9.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = ">= 5.0, < 9.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.0"
    }
  }
}
