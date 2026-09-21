resource "random_id" "project_suffix" {
  byte_length = 2
}

locals {
  apis = toset([
    "cloudresourcemanager.googleapis.com",
    "compute.googleapis.com",
    "iam.googleapis.com",
    "serviceusage.googleapis.com",
    "storage.googleapis.com",
    "run.googleapis.com",
    "dns.googleapis.com",
    "servicedirectory.googleapis.com",
    "iap.googleapis.com",
    "networkservices.googleapis.com",
    "orgpolicy.googleapis.com",
    "accesscontextmanager.googleapis.com",
  ])

  boolean_org_policies = toset([
    "compute.disableNestedVirtualization",
    "compute.disableSerialPortAccess",
    "compute.requireOsLogin",
    "compute.requireShieldedVm",
  ])

  list_org_policies = toset([
    "compute.vmExternalIpAccess",
    "compute.vmCanIpForward",
    "iam.allowedPolicyMemberDomains",
  ])
}

resource "google_project" "project" {
  name                = var.project_name
  project_id          = "${var.project_name}-${random_id.project_suffix.hex}"
  org_id              = var.organization_id
  billing_account     = var.billing_account
  auto_create_network = false
  deletion_policy     = "DELETE"
}

resource "google_project_service" "apis" {
  for_each           = local.apis
  project            = google_project.project.project_id
  service            = each.value
  disable_on_destroy = false
}

resource "google_project_organization_policy" "boolean_policies" {
  for_each   = local.boolean_org_policies
  project    = google_project.project.project_id
  constraint = each.value

  boolean_policy {
    enforced = false
  }

  depends_on = [google_project_service.apis]
}

resource "google_project_organization_policy" "list_policies" {
  for_each   = local.list_org_policies
  project    = google_project.project.project_id
  constraint = each.value

  list_policy {
    allow {
      all = true
    }
  }

  depends_on = [google_project_service.apis]
}

# GCS bucket for storing remote Terraform state of subsequent layers (02-network through 06-client-vpc)
resource "google_storage_bucket" "tfstate" {
  project                     = google_project.project.project_id
  name                        = "${google_project.project.project_id}-tfstate"
  location                    = var.region
  force_destroy               = false
  uniform_bucket_level_access = true

  versioning {
    enabled = true
  }

  lifecycle_rule {
    action {
      type = "Delete"
    }
    condition {
      num_newer_versions = 5
      with_state         = "ARCHIVED"
    }
  }

  depends_on = [google_project_service.apis]
}
