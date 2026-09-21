#!/usr/bin/env bash
set -euo pipefail

PROJECT_ID=$(terraform -chdir=../01-project output -raw project_id)
CLIENT_NAT_IP_SELF_LINK=$(terraform -chdir=../02-network output -raw client_external_nat_ip_self_link)

cat <<EOF > terraform.tfvars
project_id                       = "${PROJECT_ID}"
region                           = "australia-southeast1"
zone                             = "australia-southeast1-a"
client_external_nat_ip_self_link = "${CLIENT_NAT_IP_SELF_LINK}"
EOF

echo "Wrote 06-client-vpc/terraform.tfvars"
