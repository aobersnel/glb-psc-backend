# ==============================================================================
# 1. CLIENT VPC (Isolated VPC with Static External Cloud NAT IP)
# ==============================================================================
resource "google_compute_network" "client" {
  project                 = var.project_id
  name                    = "client-vpc"
  auto_create_subnetworks = false
  routing_mode            = "REGIONAL"
}

resource "google_compute_subnetwork" "client" {
  project                  = var.project_id
  name                     = "client-subnet"
  ip_cidr_range            = "10.30.1.0/24"
  region                   = var.region
  network                  = google_compute_network.client.id
  private_ip_google_access = true
}

resource "google_compute_router" "client_router" {
  project = var.project_id
  name    = "client-router"
  region  = var.region
  network = google_compute_network.client.id
}

resource "google_compute_router_nat" "client_nat" {
  project                            = var.project_id
  name                               = "client-nat"
  router                             = google_compute_router.client_router.name
  region                             = var.region
  nat_ip_allocate_option             = "MANUAL_ONLY"
  nat_ips                            = [var.client_external_nat_ip_self_link]
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}

# Allow IAP SSH to Client VM
resource "google_compute_firewall" "client_allow_iap" {
  project = var.project_id
  name    = "client-allow-iap"
  network = google_compute_network.client.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["35.235.240.0/20"]
  target_tags   = ["client-vm"]
}

# ==============================================================================
# 2. CLIENT ENDPOINT GCE VM (In isolated client-vpc, egressing via Cloud NAT)
# ==============================================================================
resource "google_compute_instance" "client" {
  project      = var.project_id
  name         = "client-vm"
  machine_type = "e2-medium"
  zone         = var.zone
  tags         = ["client-vm"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
      size  = 20
    }
  }

  network_interface {
    network    = google_compute_network.client.self_link
    subnetwork = google_compute_subnetwork.client.self_link
  }

  metadata_startup_script = <<-EOF
    #!/bin/bash
    set -euxo pipefail
    apt-get update && apt-get install -y curl openssl jq netcat-openbsd
  EOF

  shielded_instance_config {
    enable_secure_boot          = true
    enable_vtpm                 = true
    enable_integrity_monitoring = true
  }
}
