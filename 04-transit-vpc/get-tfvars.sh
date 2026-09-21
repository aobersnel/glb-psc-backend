#!/usr/bin/env bash
set -euo pipefail

PROJECT_ID=$(terraform -chdir=../01-project output -raw project_id)
TRANSIT_VPC=$(terraform -chdir=../02-network output -raw transit_vpc_self_link)
PSC_NEG_SUBNET=$(terraform -chdir=../02-network output -raw transit_psc_neg_subnet_self_link)
CLIENT_NAT_IP=$(terraform -chdir=../02-network output -raw client_external_nat_ip)
SERVICE_ATTACHMENT=$(terraform -chdir=../03-producer-vpc output -raw service_attachment_uri)

cat <<EOF > terraform.tfvars
project_id               = "${PROJECT_ID}"
region                   = "australia-southeast1"
transit_vpc_self_link    = "${TRANSIT_VPC}"
psc_neg_subnet_self_link = "${PSC_NEG_SUBNET}"
client_external_nat_ip   = "${CLIENT_NAT_IP}"
psc_target_service_uri   = "${SERVICE_ATTACHMENT}"
psc_neg_producer_port    = 443
tcp_proxy_header         = "NONE"
enable_cloud_armor       = true
EOF

echo "Wrote 04-transit-vpc/terraform.tfvars"
