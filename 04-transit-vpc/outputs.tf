output "global_enlb_ip" {
  description = "External VIP of the Global External Proxy Network Load Balancer"
  value       = google_compute_global_address.transit_global_enlb_ip.address
}

output "psc_neg_id" {
  description = "ID of the Private Service Connect NEG"
  value       = google_compute_region_network_endpoint_group.transit_psc_backend_neg.id
}

output "cloud_armor_policy_name" {
  description = "Name of the Cloud Armor policy attached to the Global Backend Service"
  value       = var.enable_cloud_armor ? google_compute_security_policy.transit_cloud_armor[0].name : null
}
