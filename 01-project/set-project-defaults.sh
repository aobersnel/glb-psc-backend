#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ID=$(terraform -chdir="${SCRIPT_DIR}" output -raw project_id 2>/dev/null || true)

if [[ -z "${PROJECT_ID}" ]]; then
  echo "Error: project_id output not found. Has 'terraform apply' completed in 01-project?" >&2
  exit 1
fi

REGION="australia-southeast1"
ZONE="australia-southeast1-a"

gcloud config set project "${PROJECT_ID}"
gcloud config set compute/region "${REGION}"
gcloud config set compute/zone "${ZONE}"
gcloud auth application-default set-quota-project "${PROJECT_ID}" --quiet 2>/dev/null || true

gcloud compute project-info add-metadata \
  --metadata "google-compute-default-region=${REGION},google-compute-default-zone=${ZONE}" \
  --project "${PROJECT_ID}" 2>/dev/null || true

echo "Successfully configured gcloud context for project: ${PROJECT_ID}"
