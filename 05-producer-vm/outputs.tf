output "producer_vm_name" {
  description = "Name of the Producer endpoint GCE VM"
  value       = google_compute_instance.producer.name
}

output "producer_vm_ip" {
  description = "Internal IP of the Producer endpoint GCE VM"
  value       = google_compute_instance.producer.network_interface[0].network_ip
}
