#!/usr/bin/env bash
set -euo pipefail

PROJECT_NAME="psc-enlb-demo"
REGION="australia-southeast1"
ZONE="australia-southeast1-a"

BILLING_ACCOUNT=$(gcloud beta billing accounts list --format="value(name)" 2>/dev/null | head -n1 | sed 's|billingAccounts/||' || true)
ORGANIZATION_ID=$(gcloud organizations list --format="value(name)" 2>/dev/null | head -n1 | sed 's|organizations/||' || true)

cat << EOF > terraform.tfvars
organization_id = "${ORGANIZATION_ID}"
billing_account = "${BILLING_ACCOUNT}"
project_name    = "${PROJECT_NAME}"
region          = "${REGION}"
zone            = "${ZONE}"
EOF

echo "Wrote 01-project/terraform.tfvars"
