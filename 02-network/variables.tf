variable "project_id" {
  description = "Target GCP Project ID (output from 01-project)"
  type        = string
}

variable "region" {
  description = "Primary GCP region for regional subnets and routers"
  type        = string
  default     = "australia-southeast1"
}

variable "transit_vpc_name" {
  description = "Name of the Consumer Transit VPC"
  type        = string
  default     = "transit-vpc"
}

variable "transit_psc_neg_subnet_cidr" {
  description = "Subnet CIDR in Transit VPC for the PSC NEG"
  type        = string
  default     = "10.10.1.0/24"
}

variable "producer_vpc_name" {
  description = "Name of the Producer Service VPC"
  type        = string
  default     = "producer-vpc"
}

variable "producer_backend_subnet_cidr" {
  description = "Subnet CIDR in Producer VPC for backend VM and Internal Passthrough NLB"
  type        = string
  default     = "10.20.1.0/24"
}

variable "producer_psc_nat_subnet_cidr" {
  description = "PSC NAT subnet CIDR in Producer VPC (purpose = PRIVATE_SERVICE_CONNECT)"
  type        = string
  default     = "10.20.2.0/24"
}

variable "enable_psc_nat_ingress_firewall" {
  description = "Whether to enable the firewall rule permitting ingress from the PSC NAT subnet to Producer VMs"
  type        = bool
  default     = true
}
