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

variable "client_vpc_name" {
  type    = string
  default = "client-vpc"
}

variable "client_subnet_cidr" {
  type    = string
  default = "10.30.1.0/24"
}

variable "client_external_nat_ip_self_link" {
  type = string
}
