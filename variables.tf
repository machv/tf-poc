variable "resource_group_name" {
  type = string
}

variable "name_prefix" {
  type = string
  default = ""
}

variable "location" {
  type = string
  default = "northeurope"
}

variable "deploy_bastion" {
  type = bool
  default = false
}

variable "bastion_prefix" {
  type = string
  default = "192.168.255.224/27"
}

variable "address_space" {
  type = list
  default = [ "192.168.0.0/16" ]
}

variable "subnets" {
  type = list
  default = [
    {
      name = "db"
      address_prefixes = ["192.168.0.0/24"]
      rules = [{
        name = "DenyInternetOutbound"
        priority = 100
        direction = "Outbound"
        access = "Deny"
        protocol = "*"
        source_port_range = "*"
        destination_port_range = "*"
        source_address_prefix = "*"
        destination_address_prefix = "Internet"
      }]
    },
    {
      name = "pc"
      address_prefixes = ["192.168.1.0/24"]
      rules = []
    },
    {
      name = "web"
      address_prefixes = ["192.168.2.0/24"]
      rules = []
    }
  ]
}

variable "default_user" {
  type = string
  default = "adminuser"
}

variable "default_password" {
  type = string
  default = "Azure12345678"
}

variable "web_vm_count" {
  type = number
  default = 1
}

variable "pc_vm_count" {
  type = number
  default = 1
}

variable "db_vm_count" {
  type = number
  default = 1
}

variable "enable_ping" {
  type = bool
  default = false
}
