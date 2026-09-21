variable "project_id" {
  description = "Target GCP Project ID (output from 01-project)"
  type        = string
}

variable "region" {
  description = "Primary GCP region for regional subnets and routers"
  type        = string
  default     = "australia-southeast1"
}
