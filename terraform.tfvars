resource_group_name = "cw1-poc"
location = "northeurope"
name_prefix = "cw1-poc"
web_vm_count = 1
web_vm_size = "Standard_B2ms"
db_vm_count = 1
db_vm_size = "Standard_B4ms"
pc_vm_count = 1
pc_vm_size = "Standard_B2ms"
default_user = "adminuser"
default_password = "Azure12345678"
deploy_bastion = true
address_space = [ "192.168.0.0/16" ]
bastion_prefix = "192.168.255.224/27"
subnets = [
  {
    name = "db"
    address_prefixes = ["192.168.0.0/24"]
    rules = []
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
