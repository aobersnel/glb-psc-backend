# ==============================================================================
# CONSUMER GLOBAL EXTERNAL PROXY NETWORK LB + CLOUD ARMOR + PSC NEG (transit-vpc)
# ==============================================================================

# Reserve a global external IP address for the Global External Proxy NLB
resource "google_compute_global_address" "transit_global_enlb_ip" {
  project = var.project_id
  name    = "transit-enlb-ip"
}

# Define Regional PSC NEG in Transit VPC pointing to the Producer Service Attachment
resource "google_compute_region_network_endpoint_group" "transit_psc_backend_neg" {
  project               = var.project_id
  name                  = "transit-psc-neg"
  network_endpoint_type = "PRIVATE_SERVICE_CONNECT"
  region                = var.region
  network               = var.transit_vpc_self_link
  subnetwork            = var.psc_neg_subnet_self_link
  psc_target_service    = var.psc_target_service_uri

  dynamic "psc_data" {
    for_each = var.psc_neg_producer_port != null ? [var.psc_neg_producer_port] : []
    content {
      producer_port = psc_data.value
    }
  }
}

# Cloud Armor security policy whitelisting the Client VPC static external Cloud NAT IP
resource "google_compute_security_policy" "transit_cloud_armor" {
  count   = var.enable_cloud_armor ? 1 : 0
  project = var.project_id
  name    = "transit-cloud-armor"
  type    = "CLOUD_ARMOR"

  rule {
    action   = "allow"
    priority = "1000"
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["${var.client_external_nat_ip}/32"]
      }
    }
    description = "Allow traffic from Client VPC static external Cloud NAT IP"
  }

  rule {
    action   = "deny(403)"
    priority = "2147483647"
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["*"]
      }
    }
    description = "Default deny rule (only whitelisted Client NAT IP permitted)"
  }
}

# Define Global Backend Service using the Regional PSC NEG
resource "google_compute_backend_service" "transit_psc_global_bs" {
  project               = var.project_id
  name                  = "transit-enlb-bs"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  protocol              = "TCP"
  timeout_sec           = 150
  security_policy       = var.enable_cloud_armor ? google_compute_security_policy.transit_cloud_armor[0].self_link : null

  backend {
    group = google_compute_region_network_endpoint_group.transit_psc_backend_neg.self_link
  }

  log_config {
    enable = true
  }
}

# Define Global Target TCP Proxy
resource "google_compute_target_tcp_proxy" "transit_psc_global_tcp_proxy" {
  project         = var.project_id
  name            = "transit-tcp-proxy"
  backend_service = google_compute_backend_service.transit_psc_global_bs.id
  proxy_header    = var.tcp_proxy_header
}

# Define Global Forwarding Rule (EXTERNAL_MANAGED)
resource "google_compute_global_forwarding_rule" "transit_global_enlb" {
  provider              = google-beta
  project               = var.project_id
  name                  = "transit-enlb"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  ip_address            = google_compute_global_address.transit_global_enlb_ip.address
  target                = google_compute_target_tcp_proxy.transit_psc_global_tcp_proxy.id
  ip_protocol           = "TCP"
  port_range            = "443"
}
