# ==============================================================================
# 1. PRODUCER UNMANAGED INSTANCE GROUP (Populated by 05-producer-vm)
# ==============================================================================
resource "google_compute_instance_group" "producer_ig" {
  project = var.project_id
  name    = "producer-ig"
  zone    = var.zone
  network = var.producer_vpc_self_link

  named_port {
    name = "tls-service"
    port = 443
  }

  lifecycle {
    ignore_changes = [instances]
  }
}

# ==============================================================================
# 2. PRODUCER INTERNAL NETWORK PASSTHROUGH LB
# ==============================================================================
resource "google_compute_health_check" "producer_hc" {
  project = var.project_id
  name    = "producer-hc"

  tcp_health_check {
    port = 443
  }
}

resource "google_compute_region_backend_service" "producer_ilb_bs" {
  project               = var.project_id
  name                  = "producer-ilb-bs"
  region                = var.region
  load_balancing_scheme = "INTERNAL"
  protocol              = "TCP"
  network               = var.producer_vpc_self_link
  health_checks         = [google_compute_health_check.producer_hc.id]

  backend {
    group          = google_compute_instance_group.producer_ig.self_link
    balancing_mode = "CONNECTION"
  }
}

resource "google_compute_forwarding_rule" "producer_ilb_fr" {
  project               = var.project_id
  name                  = "producer-ilb"
  region                = var.region
  load_balancing_scheme = "INTERNAL"
  backend_service       = google_compute_region_backend_service.producer_ilb_bs.id
  ip_protocol           = "TCP"
  network               = var.producer_vpc_self_link
  subnetwork            = var.producer_backend_subnet_self_link

  # Required when accessed by a Global External Proxy NLB + PSC NEG
  allow_global_access = var.ilb_allow_global_access

  # Single/Explicit ports vs all_ports (if all_ports = true, Consumer PSC NEG must specify producer_port)
  all_ports = var.ilb_all_ports ? true : null
  ports     = var.ilb_all_ports ? null : var.ilb_ports
}

# ==============================================================================
# 3. PRODUCER PSC SERVICE ATTACHMENT
# ==============================================================================
resource "google_compute_service_attachment" "producer_psc_service" {
  project               = var.project_id
  name                  = var.service_attachment_name
  region                = var.region
  connection_preference = var.connection_preference
  enable_proxy_protocol = var.enable_proxy_protocol
  nat_subnets           = [var.producer_psc_nat_subnet_self_link]
  target_service        = google_compute_forwarding_rule.producer_ilb_fr.id
}
