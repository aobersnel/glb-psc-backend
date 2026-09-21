#!/usr/bin/env bash
set -euo pipefail

PROJECT_ID=$(terraform -chdir=../01-project output -raw project_id)
PRODUCER_VPC=$(terraform -chdir=../02-network output -raw producer_vpc_self_link)
BACKEND_SUBNET=$(terraform -chdir=../02-network output -raw producer_backend_subnet_self_link)
PSC_NAT_SUBNET=$(terraform -chdir=../02-network output -raw producer_psc_nat_subnet_self_link)

cat <<EOF > terraform.tfvars
project_id                        = "${PROJECT_ID}"
region                            = "australia-southeast1"
zone                              = "australia-southeast1-a"
producer_vpc_self_link            = "${PRODUCER_VPC}"
producer_backend_subnet_self_link = "${BACKEND_SUBNET}"
producer_psc_nat_subnet_self_link = "${PSC_NAT_SUBNET}"
ilb_allow_global_access           = true
ilb_all_ports                     = true
ilb_ports                         = ["443"]
connection_preference             = "ACCEPT_AUTOMATIC"
enable_proxy_protocol             = false
EOF

echo "Wrote 03-producer-vpc/terraform.tfvars"
