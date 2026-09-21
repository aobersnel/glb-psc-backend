#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_ID=$(terraform -chdir="${ROOT_DIR}/01-project" output -raw project_id)

cat <<EOF > terraform.tfvars
project_id                      = "${PROJECT_ID}"
region                          = "australia-southeast1"
enable_psc_nat_ingress_firewall = true
EOF

echo "Wrote 02-network/terraform.tfvars"
