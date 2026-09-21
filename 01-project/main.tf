resource "random_id" "project_suffix" {
  byte_length = 2
}

locals {
  project_id = var.random_project_id ? "${var.project_name}-${random_id.project_suffix.hex}" : var.project_name

  boolean_org_policies = var.relax_org_policies ? toset([
    "compute.disableNestedVirtualization",
    "compute.disableSerialPortAccess",
    "compute.requireOsLogin",
    "compute.requireShieldedVm",
  ]) : toset([])

  list_org_policies = var.relax_org_policies ? toset([
    "compute.vmExternalIpAccess",
    "compute.vmCanIpForward",
    "iam.allowedPolicyMemberDomains",
  ]) : toset([])

  iam_members_flattened = flatten([
    for role, members in var.project_iam_members : [
      for member in members : {
        role   = role
        member = member
      }
    ]
  ])
}

resource "google_project" "project" {
  name                = var.project_name
  project_id          = local.project_id
  org_id              = var.folder_id == "" ? var.organization_id : null
  folder_id           = var.folder_id != "" ? var.folder_id : null
  billing_account     = var.billing_account
  auto_create_network = var.auto_create_network
  deletion_policy     = "DELETE"
}

resource "google_project_service" "apis" {
  for_each           = toset(var.activate_apis)
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

resource "google_project_iam_member" "project_members" {
  for_each = {
    for item in local.iam_members_flattened : "${item.role}/${item.member}" => item
  }

  project    = google_project.project.project_id
  role       = each.value.role
  member     = each.value.member
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
