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

variable "producer_instance_group_self_link" {
  type = string
}
