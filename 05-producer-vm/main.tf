# ==============================================================================
# 1. PRODUCER ENDPOINT GCE VM (Simulating Backend TLS Service on Port 443)
# ==============================================================================
resource "google_compute_instance" "producer" {
  project      = var.project_id
  name         = "producer-vm"
  machine_type = "e2-medium"
  zone         = var.zone
  tags         = ["producer-vm"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
      size  = 20
    }
  }

  network_interface {
    network    = var.producer_vpc_self_link
    subnetwork = var.producer_backend_subnet_self_link
  }

  metadata_startup_script = <<-EOF
    #!/bin/bash
    set -euxo pipefail
    apt-get update && apt-get install -y openssl python3

    mkdir -p /opt/producer-service
    openssl req -x509 -newkey rsa:2048 -nodes \
      -keyout /opt/producer-service/key.pem \
      -out /opt/producer-service/cert.pem \
      -days 365 \
      -subj "/CN=tls-backend.example.internal"

    cat <<'PY' > /opt/producer-service/server.py
    import http.server
    import ssl
    import json
    import socket

    class ProducerHandler(http.server.BaseHTTPRequestHandler):
        def do_GET(self):
            body = json.dumps({
                "service": "producer-tls-simulator",
                "hostname": socket.gethostname(),
                "client_address": self.client_address[0],
                "client_port": self.client_address[1],
                "path": self.path,
                "status": "CONNECTED_THROUGH_PSC_TO_PRODUCER"
            }, indent=2).encode("utf-8") + b"\n"
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)

    server = http.server.ThreadingHTTPServer(("0.0.0.0", 443), ProducerHandler)
    ctx = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
    ctx.load_cert_chain(certfile="/opt/producer-service/cert.pem", keyfile="/opt/producer-service/key.pem")
    server.socket = ctx.wrap_socket(server.socket, server_side=True)
    server.serve_forever()
    PY

    cat <<'UNIT' > /etc/systemd/system/producer-tls.service
    [Unit]
    Description=Producer TLS 443 Endpoint Responder
    After=network.target

    [Service]
    ExecStart=/usr/bin/python3 /opt/producer-service/server.py
    Restart=always

    [Install]
    WantedBy=multi-user.target
    UNIT

    systemctl daemon-reload
    systemctl enable --now producer-tls.service
  EOF

  shielded_instance_config {
    enable_secure_boot          = true
    enable_vtpm                 = true
    enable_integrity_monitoring = true
  }
}

# ==============================================================================
# 2. REGISTER PRODUCER VM INTO 03-PRODUCER-VPC UNMANAGED INSTANCE GROUP
# ==============================================================================
resource "google_compute_instance_group_membership" "producer_membership" {
  project        = var.project_id
  zone           = var.zone
  instance_group = var.producer_instance_group_self_link
  instance       = google_compute_instance.producer.self_link
}
