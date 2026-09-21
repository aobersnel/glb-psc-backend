#!/usr/bin/env bash
set -euo pipefail

LAYER_DIR="${1:-}"

if [[ -z "${LAYER_DIR}" ]]; then
  echo "Usage: $0 <layer-directory> [bucket-name]"
  echo "Example: $0 02-network"
  exit 1
fi

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TARGET_DIR="${ROOT_DIR}/${LAYER_DIR}"

if [[ ! -d "${TARGET_DIR}" ]]; then
  echo "Error: Directory ${TARGET_DIR} does not exist." >&2
  exit 1
fi

BUCKET="${2:-}"

if [[ -z "${BUCKET}" ]]; then
  # Try to read bucket from 01-project output
  BUCKET=$(terraform -chdir="${ROOT_DIR}/01-project" output -raw tfstate_bucket_name 2>/dev/null || true)
fi

if [[ -z "${BUCKET}" ]]; then
  echo "Error: GCS tfstate bucket name not provided and could not be determined from 01-project outputs." >&2
  echo "Provide it manually: $0 ${LAYER_DIR} <bucket-name>" >&2
  exit 1
fi

echo "==> Initializing Terraform in ${LAYER_DIR} with backend bucket: ${BUCKET}"
terraform -chdir="${TARGET_DIR}" init -backend-config="bucket=${BUCKET}"
echo "==> Initialization complete for ${LAYER_DIR}"
