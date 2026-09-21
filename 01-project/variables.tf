variable "organization_id" {
  description = "The GCP organization ID (e.g. from gcloud organizations list)"
  type        = string
}

variable "billing_account" {
  description = "The billing account ID to associate with the project"
  type        = string
}

variable "project_name" {
  description = "The base name of the GCP project to create"
  type        = string
  default     = "psc-enlb-demo"
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
