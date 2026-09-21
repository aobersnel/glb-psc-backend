output "producer_instance_group_self_link" {
  description = "Self link of the unmanaged instance group for the Producer VM (used by 05-producer-vm)"
  value       = google_compute_instance_group.producer_ig.self_link
}

output "producer_ilb_ip" {
  description = "Internal IP of the Producer Internal Network Passthrough LB"
  value       = google_compute_forwarding_rule.producer_ilb_fr.ip_address
}

output "service_attachment_uri" {
  description = "URI of the Producer PSC Service Attachment (used by 04-transit-vpc)"
  value       = "projects/${var.project_id}/regions/${var.region}/serviceAttachments/${google_compute_service_attachment.producer_psc_service.name}"
}
