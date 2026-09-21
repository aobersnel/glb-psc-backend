variable "project_id" {
  type = string
}

variable "region" {
  type    = string
  default = "australia-southeast1"
}

variable "transit_vpc_self_link" {
  type = string
}

variable "psc_neg_subnet_self_link" {
  type = string
}

variable "psc_target_service_uri" {
  type = string
}

variable "client_external_nat_ip" {
  type = string
}
