variable "project_id" {
  type = string
}

variable "region" {
  type    = string
  default = "australia-southeast1"
}

variable "zone" {
  type    = string
  default = "australia-southeast1-a"
}

variable "producer_vpc_self_link" {
  type = string
}

variable "producer_backend_subnet_self_link" {
  type = string
}

variable "producer_psc_nat_subnet_self_link" {
  type = string
}

variable "ilb_allow_global_access" {
  type    = bool
  default = true
}

variable "ilb_all_ports" {
  type    = bool
  default = true
}

variable "ilb_ports" {
  type    = list(string)
  default = ["443"]
}

variable "service_attachment_name" {
  type    = string
  default = "producer-psc-attachment"
}

variable "connection_preference" {
  type    = string
  default = "ACCEPT_AUTOMATIC"
}

variable "enable_proxy_protocol" {
  type    = bool
  default = false
}
