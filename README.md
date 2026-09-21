# glb-psc-backend

Six-layer Terraform reference architecture for routing TCP/TLS traffic from a Global External Proxy Network Load Balancer (`EXTERNAL_MANAGED`) protected by Cloud Armor through a Regional Private Service Connect (`PSC`) Network Endpoint Group (`NEG`) to an isolated Producer VPC.\
Each layer (`01-project` through `06-client-vpc`) is a flat, standalone Terraform root module with no child module abstractions.

**Status:** production.

---

## Prerequisites

Assumes authenticated `gcloud` (`gcloud auth login` and `gcloud auth application-default login`) and `terraform` (`>= 1.5.0`) with permissions to create projects, VPCs, load balancers, and Cloud Storage buckets under your organization and billing account.

---

## Install

Bootstrap the project and local state in `01-project`, configure `gcloud` defaults, and apply layers `02-network` through `06-client-vpc` against the remote `gcs` state bucket created by `01-project`:

```bash
set -euo pipefail

cd 01-project
./get-tfvars.sh
terraform init
terraform apply -auto-approve
./set-project-defaults.sh

PROJECT_ID=$(terraform output -raw project_id)
BUCKET_NAME=$(terraform output -raw tfstate_bucket_name)
cd ..

for layer in 02-network 03-producer-vpc 04-transit-vpc 05-producer-vm 06-client-vpc; do
  cd "${layer}"
  ./get-tfvars.sh
  ../scripts/init-layer.sh "${layer}" "${BUCKET_NAME}"
  terraform apply -auto-approve
  cd ..
done
```

---

## Use

Query the deployed Global External Proxy Network Load Balancer VIP and the whitelisted Client Cloud NAT external IP:

```bash
PROJECT_ID=$(terraform -chdir=01-project output -raw project_id)
GLOBAL_ENLB_IP=$(terraform -chdir=04-transit-vpc output -raw global_enlb_ip)
CLIENT_NAT_IP=$(terraform -chdir=02-network output -raw client_external_nat_ip)
printf "Project: %s\nGlobal ENLB VIP: %s\nWhitelisted Client NAT IP: %s\n" \
  "${PROJECT_ID}" "${GLOBAL_ENLB_IP}" "${CLIENT_NAT_IP}"
```

---

## Test

Run the positive connectivity test from `client-vm` (egressing via the whitelisted `client-nat-ip` `/32` in `06-client-vpc`) through the Global External Proxy NLB (`04-transit-vpc`) and Regional PSC NEG to `producer-vm` (`05-producer-vm`):

```bash
PROJECT_ID=$(terraform -chdir=01-project output -raw project_id)
GLOBAL_ENLB_IP=$(terraform -chdir=04-transit-vpc output -raw global_enlb_ip)

gcloud compute ssh client-vm \
  --project="${PROJECT_ID}" \
  --zone="australia-southeast1-a" \
  --tunnel-through-iap \
  --command="curl -skv https://${GLOBAL_ENLB_IP}/status"
```

Run the negative test from `producer-vm` (whose egress NAT IP is not in the Cloud Armor `/32` allowlist) to verify edge rejection:

```bash
PROJECT_ID=$(terraform -chdir=01-project output -raw project_id)
GLOBAL_ENLB_IP=$(terraform -chdir=04-transit-vpc output -raw global_enlb_ip)

gcloud compute ssh producer-vm \
  --project="${PROJECT_ID}" \
  --zone="australia-southeast1-a" \
  --tunnel-through-iap \
  --command="curl -skv --connect-timeout 5 https://${GLOBAL_ENLB_IP}/status || true"
```

---

## Remove

Destroy layers `06-client-vpc` down to `02-network` in reverse dependency order, then remove the remote state bucket and bootstrap project:

```bash
set -euo pipefail

PROJECT_ID=$(terraform -chdir=01-project output -raw project_id)
BUCKET_NAME=$(terraform -chdir=01-project output -raw tfstate_bucket_name)

for layer in 06-client-vpc 05-producer-vm 04-transit-vpc 03-producer-vpc 02-network; do
  terraform -chdir="${layer}" destroy -auto-approve
done

gcloud storage rm -r "gs://${BUCKET_NAME}/**" || true
terraform -chdir=01-project destroy -auto-approve
```

---

## Architecture

The architecture isolates the Client, Consumer Transit, and Producer planes across three VPC networks and six ordered Terraform layers:

```text
┌────────────────────┐   ┌──────────────────────────────────┐   ┌─────────────────────┐
│   Client VPC (1)   │   │     Transit VPC (2 - Consumer)   │   │   Producer VPC (3)  │
│     client-vpc     │   │            transit-vpc           │   │     producer-vpc    │
│  [06-client-vpc]   │   │         [04-transit-vpc]         │   │  [03-producer-vpc]  │
│ ┌────────────────┐ │   │ ┌──────────────────────────────┐ │   │  ┌───────────────┐  │
│ │   client-vm    │ │   │ │ Global External Proxy NLB    │ │   ┌->│  PSC Service  │  │
│ │   (GCE VM)     │ │   │ │   (transit-enlb / TCP:443)   │ │   │  │ (Attachment)  │  │
│ └───────┬────────┘ │   │ └──────────────┬───────────────┘ │   │  └───────┬───────┘  │
│         │          │   │                │                 │   │          │          │
│         v          │   │ ┌──────────────v───────────────┐ │   │          v          │
│ ┌────────────────┐ │   │ │   Cloud Armor Edge Policy    │ │   │  ┌───────────────┐  │
│ │   client-nat   ├─┼──>│ │     (transit-cloud-armor)    │ │   │  │ producer-ilb  │  │
│ │ (client-nat-ip)│ │   │ └──────────────┬───────────────┘ │   │  │Passthrough LB │  │
│ └────────────────┘ │   │                │                 │   │  │(global_access)│  │
│                    │   │                v                 │   │  └───────┬───────┘  │
│                    │   │ ┌──────────────────────────────┐ │   │          │          │
│                    │   │ │      transit-psc-neg         ├─┼───┘  ┌───────v───────┐  │
│                    │   │ │   (producer_port = 443)      │ │      │  producer-vm  │  │
│                    │   │ └──────────────────────────────┘ │      │ (TLS on :443) │  │
│                    │   │                                  │      │[05-producer-vm│  │
└────────────────────┘   └──────────────────────────────────┘   └─────────────────────┘
```

| Layer | Directory | State Storage | Resources Owned in `main.tf` |
| :--- | :--- | :--- | :--- |
| `01` | `01-project/` | `backend "local" {}` | `google_project`, APIs, Org Policies, and `gs://<project_id>-tfstate` |
| `02` | `02-network/` | `gs://<project_id>-tfstate` (`psc-enlb-demo/02-network`) | `transit-vpc`, `transit-psc-subnet`, `producer-vpc`, `producer-subnet`, `producer-psc-subnet`, `producer-router`, `producer-nat`, `producer-allow-iap`, `producer-allow-hc`, `producer-allow-psc`, `client-nat-ip` |
| `03` | `03-producer-vpc/` | `gs://<project_id>-tfstate` (`psc-enlb-demo/03-producer-vpc`) | `producer-ig`, `producer-hc`, `producer-ilb-bs`, `producer-ilb` (`allow_global_access = true`, `all_ports = true`), `producer-psc-attachment` |
| `04` | `04-transit-vpc/` | `gs://<project_id>-tfstate` (`psc-enlb-demo/04-transit-vpc`) | `transit-enlb-ip`, `transit-psc-neg` (`psc_data { producer_port = 443 }`), `transit-cloud-armor`, `transit-enlb-bs`, `transit-tcp-proxy`, `transit-enlb` |
| `05` | `05-producer-vm/` | `gs://<project_id>-tfstate` (`psc-enlb-demo/05-producer-vm`) | `producer-vm` (`TCP/443` TLS responder) and `google_compute_instance_group_membership` |
| `06` | `06-client-vpc/` | `gs://<project_id>-tfstate` (`psc-enlb-demo/06-client-vpc`) | `client-vpc`, `client-subnet`, `client-router`, `client-nat` (bound to `client-nat-ip`), `client-allow-iap`, `client-vm` |

---

## Why this exists

When a Global External Proxy Network Load Balancer (`EXTERNAL_MANAGED`) routes traffic through a Regional `PRIVATE_SERVICE_CONNECT` NEG (`google_compute_region_network_endpoint_group`) to a Producer Service Attachment backed by an Internal Passthrough Network Load Balancer configured with `all_ports = true`, two properties must hold simultaneously:

1. **Global Access on the Producer Internal LB:** The Producer `google_compute_forwarding_rule` (`producer-ilb` in `03-producer-vpc/main.tf`) must set `allow_global_access = true`.
2. **Explicit `producer_port` on the Regional PSC NEG:** Because the Producer Internal LB uses `all_ports = true` rather than a single port, omitting `psc_data { producer_port = 443 }` on the Consumer `google_compute_region_network_endpoint_group` (`transit-psc-neg` in `04-transit-vpc/main.tf`) causes Google Cloud to default the PSC destination port to `TCP/1`, resulting in a 5-second connection timeout (`SSL_ERROR_SYSCALL`).
