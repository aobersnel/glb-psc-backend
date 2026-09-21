output "project_id" {
  description = "The globally unique ID of the created GCP project"
  value       = google_project.project.project_id
}

output "project_number" {
  description = "The numeric project number"
  value       = google_project.project.number
}

output "project_name" {
  description = "The project display name"
  value       = google_project.project.name
}

output "tfstate_bucket_name" {
  description = "The name of the GCS bucket created for downstream layers remote state"
  value       = google_storage_bucket.tfstate.name
}

output "tfstate_bucket_url" {
  description = "The GCS URL of the remote state bucket"
  value       = google_storage_bucket.tfstate.url
}
