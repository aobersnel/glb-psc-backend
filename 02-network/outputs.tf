output "transit_vpc_self_link" {
  description = "Self link of the Consumer Transit VPC"
  value       = google_compute_network.transit.self_link
}

output "transit_psc_neg_subnet_self_link" {
  description = "Self link of the Transit VPC subnet hosting the PSC NEG"
  value       = google_compute_subnetwork.transit_psc_neg.self_link
}

output "producer_vpc_self_link" {
  description = "Self link of the Producer VPC"
  value       = google_compute_network.producer.self_link
}

output "producer_backend_subnet_self_link" {
  description = "Self link of the Producer backend subnet"
  value       = google_compute_subnetwork.producer_backend.self_link
}

output "producer_psc_nat_subnet_self_link" {
  description = "Self link of the Producer PSC NAT subnet"
  value       = google_compute_subnetwork.producer_psc_nat.self_link
}

output "client_external_nat_ip" {
  description = "Static external IP reserved for Client Cloud NAT (whitelisted in 04-transit-vpc Cloud Armor)"
  value       = google_compute_address.client_nat_ip.address
}

output "client_external_nat_ip_self_link" {
  description = "Self link of the static external IP reserved for Client Cloud NAT (used by 06-client-vpc)"
  value       = google_compute_address.client_nat_ip.self_link
}
