module "vm_web" {
  count = var.web_vm_count

  source = "./modules/vm"
  
  resource_group_name = var.resource_group_name
  location = var.location

  subnet_id = azurerm_subnet.subnets["web"].id
  name = "web${count.index + 1}"
  name_prefix = var.name_prefix
  os_name = "CW1-PoC-WEB${count.index + 1}"
  size = "Standard_B2ms"   

  admin_username = var.default_user
  admin_password = var.default_password

  enable_ping = var.enable_ping
}

resource "azurerm_virtual_machine_extension" "iis" {
  count = var.web_vm_count
  name = "InstallWebServerRole"
  virtual_machine_id = module.vm_web[count.index].virtual_machine_id
  publisher = "Microsoft.Compute"
  type = "CustomScriptExtension"
  type_handler_version = "1.9"

  settings = <<SETTINGS
  {
    "commandToExecute": "powershell -command \"Install-WindowsFeature -name Web-Server -IncludeManagementTools\""
  }
  SETTINGS
}

module "vm_pc" {
  count = var.pc_vm_count

  source = "./modules/vm"
  
  resource_group_name = var.resource_group_name
  location = var.location

  subnet_id = azurerm_subnet.subnets["pc"].id
  name = "pc${count.index + 1}"
  name_prefix = var.name_prefix
  os_name = "CW1-PoC-PC${count.index + 1}"
  size = "Standard_B2ms"   

  admin_username = var.default_user
  admin_password = var.default_password

  enable_ping = var.enable_ping
}

module "vm_db" {
  count = var.db_vm_count

  source = "./modules/vm"
  
  resource_group_name = var.resource_group_name
  location = var.location

  use_mssql = true
  mssql_data_settings = {
    file_path = "F:\\Data"
    luns = [1]
  }
  mssql_log_settings = {
    file_path = "G:\\Log"
    luns = [2]
  }
  mssql_temp_db_settings = {
    file_path = "H:\\TempDB"
    luns = [3]
  }
  data_disks = [
    {
        name = "data"
        tier = "Premium_LRS"
        size_gb = 1024
        lun = 1
    },
    {
        name = "temp"
        tier = "Premium_LRS"
        size_gb = 80
        lun = 2
    },
    {
        name = "log"
        tier = "Premium_LRS"
        size_gb = 500
        lun = 3
    }
  ]

  subnet_id = azurerm_subnet.subnets["db"].id
  name = "db${count.index + 1}"
  name_prefix = var.name_prefix
  os_name = "CW1-PoC-DB${count.index + 1}"
  size = "Standard_B2ms"   

  admin_username = var.default_user
  admin_password = var.default_password

  enable_ping = var.enable_ping 
}
