# ==============================================================================
# 1. CONSUMER TRANSIT VPC
# ==============================================================================
resource "google_compute_network" "transit" {
  project                 = var.project_id
  name                    = var.transit_vpc_name
  auto_create_subnetworks = false
  routing_mode            = "GLOBAL"
}

# Subnet hosting the Consumer PSC NEG
resource "google_compute_subnetwork" "transit_psc_neg" {
  project                  = var.project_id
  name                     = "transit-psc-subnet"
  ip_cidr_range            = var.transit_psc_neg_subnet_cidr
  region                   = var.region
  network                  = google_compute_network.transit.id
  private_ip_google_access = true
}

# ==============================================================================
# 2. PRODUCER SERVICE VPC
# ==============================================================================
resource "google_compute_network" "producer" {
  project                 = var.project_id
  name                    = var.producer_vpc_name
  auto_create_subnetworks = false
  routing_mode            = "REGIONAL"
}

# Primary workload subnet for Producer backend VM and Internal Passthrough NLB
resource "google_compute_subnetwork" "producer_backend" {
  project                  = var.project_id
  name                     = "producer-subnet"
  ip_cidr_range            = var.producer_backend_subnet_cidr
  region                   = var.region
  network                  = google_compute_network.producer.id
  private_ip_google_access = true
}

# Dedicated PSC NAT subnet for the Producer Service Attachment
resource "google_compute_subnetwork" "producer_psc_nat" {
  project       = var.project_id
  name          = "producer-psc-subnet"
  ip_cidr_range = var.producer_psc_nat_subnet_cidr
  region        = var.region
  network       = google_compute_network.producer.id
  purpose       = "PRIVATE_SERVICE_CONNECT"
}

# Cloud Router & Cloud NAT in Producer VPC so Producer VM can install packages on startup
resource "google_compute_router" "producer_router" {
  project = var.project_id
  name    = "producer-router"
  region  = var.region
  network = google_compute_network.producer.id
}

resource "google_compute_router_nat" "producer_nat" {
  project                            = var.project_id
  name                               = "producer-nat"
  router                             = google_compute_router.producer_router.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"

  subnetwork {
    name                    = google_compute_subnetwork.producer_backend.id
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }
}

# Allow IAP SSH to Producer VM
resource "google_compute_firewall" "producer_allow_iap" {
  project = var.project_id
  name    = "producer-allow-iap"
  network = google_compute_network.producer.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["35.235.240.0/20"]
  target_tags   = ["producer-vm"]
}

# Allow Google Cloud Health Checks & Producer subnet traffic to Producer VM
resource "google_compute_firewall" "producer_allow_hc_and_internal" {
  project = var.project_id
  name    = "producer-allow-hc"
  network = google_compute_network.producer.name

  allow {
    protocol = "tcp"
    ports    = ["443", "1883", "8883"]
  }

  source_ranges = [
    "35.191.0.0/16",
    "130.211.0.0/22",
    var.producer_backend_subnet_cidr,
  ]
  target_tags = ["producer-vm"]
}

# Toggleable Firewall Rule: Allow PSC NAT subnet traffic to Producer VM
resource "google_compute_firewall" "producer_allow_psc_nat" {
  count   = var.enable_psc_nat_ingress_firewall ? 1 : 0
  project = var.project_id
  name    = "producer-allow-psc"
  network = google_compute_network.producer.name

  allow {
    protocol = "tcp"
    ports    = ["443", "1883", "8883"]
  }

  source_ranges = [var.producer_psc_nat_subnet_cidr]
  target_tags   = ["producer-vm"]
}

# ==============================================================================
# 3. RESERVED STATIC EXTERNAL IP FOR CLIENT NAT (Shared with 04-transit-vpc & 06-client-vpc)
# ==============================================================================
resource "google_compute_address" "client_nat_ip" {
  project      = var.project_id
  name         = "client-nat-ip"
  region       = var.region
  address_type = "EXTERNAL"
  network_tier = "PREMIUM"
}
