variable "prefix" {
  description = "The Prefix used for all resources in this example"
  default     = "linux-vmss"
}

variable "location" {
  default = "South Central US"
}

variable "address_space" {
  default = "10.5.0.0/16"
}

variable "subnet_prefixes" {
  default = [
    "10.5.0.0/24",
    "10.5.1.0/24",
    "10.5.2.0/24"
  ]
}

variable "subnet_names" {
  default = [
    "subnet1",
    "subnet2",
    "subnet3"
  ]
}

variable "application_port" {
  default = "80"
}

variable "tags" {
  default = {
    environment = "Engineering"
    costcenter  = "IT"
  }
}

variable "router_wan_ip" {}
variable "admin_username" {}
variable "admin_password" {}
variable "ssh_key" {}

