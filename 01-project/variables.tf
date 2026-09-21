variable "project_name" {
  description = "The base name of the GCP project to create"
  type        = string
  default     = "psc-enlb-demo"
}

variable "organization_id" {
  description = "The GCP organization ID (e.g. from gcloud organizations list)"
  type        = string
}

variable "billing_account" {
  description = "The billing account ID to associate with the project"
  type        = string
}

variable "folder_id" {
  description = "The optional folder ID to place the project under"
  type        = string
  default     = ""
}

variable "region" {
  description = "Default GCP region for resources and state bucket"
  type        = string
  default     = "australia-southeast1"
}

variable "zone" {
  description = "Default GCP zone"
  type        = string
  default     = "australia-southeast1-a"
}

variable "random_project_id" {
  description = "Whether to append a random suffix to project_id for global uniqueness"
  type        = bool
  default     = true
}

variable "auto_create_network" {
  description = "Whether to create the default VPC network (disabled by default for custom network layer)"
  type        = bool
  default     = false
}

variable "activate_apis" {
  description = "List of APIs to enable on the project"
  type        = list(string)
  default = [
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
    "accesscontextmanager.googleapis.com"
  ]
}

variable "relax_org_policies" {
  description = "Whether to relax restrictive Org Policies"
  type        = bool
  default     = true
}

variable "project_iam_members" {
  description = "Map of IAM role -> list of member strings"
  type        = map(list(string))
  default     = {}
}
