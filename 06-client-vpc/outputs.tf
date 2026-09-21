output "client_vpc_self_link" {
  value = google_compute_network.client.self_link
}

output "client_subnet_self_link" {
  value = google_compute_subnetwork.client.self_link
}

output "client_vm_name" {
  value = google_compute_instance.client.name
}

output "client_vm_internal_ip" {
  value = google_compute_instance.client.network_interface[0].network_ip
}
