#!/usr/bin/env bash
set -euo pipefail

PROJECT_ID=$(terraform -chdir=../01-project output -raw project_id)
PRODUCER_VPC=$(terraform -chdir=../02-network output -raw producer_vpc_self_link)
BACKEND_SUBNET=$(terraform -chdir=../02-network output -raw producer_backend_subnet_self_link)
PRODUCER_IG=$(terraform -chdir=../03-producer-vpc output -raw producer_instance_group_self_link)

cat <<EOF > terraform.tfvars
project_id                        = "${PROJECT_ID}"
region                            = "australia-southeast1"
zone                              = "australia-southeast1-a"
producer_vpc_self_link            = "${PRODUCER_VPC}"
producer_backend_subnet_self_link = "${BACKEND_SUBNET}"
producer_instance_group_self_link = "${PRODUCER_IG}"
EOF

echo "Wrote 05-producer-vm/terraform.tfvars"
