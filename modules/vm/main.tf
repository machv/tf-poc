locals {
    vm_name = "${var.name_prefix}-${var.name}"
    disks = { for disk in var.data_disks : disk.name => disk }
}

resource "azurerm_network_interface" "nic" {
  name = "${var.name_prefix}-${var.name}-nic01"
  resource_group_name = var.resource_group_name
  location = var.location

  ip_configuration {
    name = "internal"
    subnet_id = var.subnet_id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_windows_virtual_machine" "vm" {
  name = local.vm_name
  computer_name = var.os_name
  resource_group_name = var.resource_group_name
  location = var.location
  size = var.size
  admin_username = var.admin_username
  admin_password = var.admin_password

  network_interface_ids = [
    azurerm_network_interface.nic.id
  ]

  os_disk {
    caching = "ReadWrite"
    storage_account_type = "Premium_LRS"
    name = "${var.name_prefix}-${var.name}-disk-os"
  }

  dynamic "source_image_reference" {
    for_each = var.use_mssql ? [] : [1]

    content {
      publisher = "MicrosoftWindowsServer"
      offer = "WindowsServer"
      sku = "2016-Datacenter"
      version = "latest"
    }
  }

  dynamic "source_image_reference" {
    for_each = var.use_mssql ? [1] : []

    content {
        publisher = "MicrosoftSQLServer"
        offer = "sql2017-ws2016"
        sku = "enterprise"
        version = "latest"
    }
  }

  boot_diagnostics {}
}

resource "azurerm_managed_disk" "datadisk" {
  for_each = local.disks

  depends_on = [
    azurerm_windows_virtual_machine.vm
  ]

  name = "${local.vm_name}-disk-${each.value.name}"
  location = var.location
  resource_group_name = var.resource_group_name
  storage_account_type = each.value.tier
  create_option = "Empty"
  disk_size_gb = each.value.size_gb
}

resource "azurerm_virtual_machine_data_disk_attachment" "datadisk_attach" {
  for_each = local.disks

  managed_disk_id = azurerm_managed_disk.datadisk[each.key].id
  virtual_machine_id = azurerm_windows_virtual_machine.vm.id
  lun = each.value.lun
  caching = "ReadWrite"
}

resource "azurerm_mssql_virtual_machine" "mssql" {
  count = var.use_mssql ? 1 : 0

  depends_on = [
    azurerm_virtual_machine_data_disk_attachment.datadisk_attach
  ]

  virtual_machine_id = azurerm_windows_virtual_machine.vm.id
  sql_license_type = "PAYG"
  sql_connectivity_update_password = var.admin_password
  sql_connectivity_update_username = var.admin_username

  storage_configuration {
    disk_type = "NEW"
    storage_workload_type = "OLTP"

    dynamic "data_settings" {
      for_each = var.mssql_data_settings == null ? [] : [var.mssql_data_settings] // if key exists, return it as single item to process
      iterator = settings

      content {
        luns = settings.value.luns
        default_file_path = settings.value.file_path
      }
    }

    dynamic "log_settings" {
      for_each = var.mssql_log_settings == null ? [] : [var.mssql_log_settings] // if key exists, return it as single item to process
      iterator = settings

      content {
        luns = settings.value.luns
        default_file_path = settings.value.file_path
      }
    }

    dynamic "temp_db_settings" {
      for_each = var.mssql_temp_db_settings == null ? [] : [var.mssql_temp_db_settings] // if key exists, return it as single item to process
      iterator = settings

      content {
        luns = settings.value.luns
        default_file_path = settings.value.file_path
      }
    }
  }
}

resource "azurerm_virtual_machine_extension" "ping" {
  count = var.enable_ping ? 1 : 0
  
  name = "EnablePing"
  virtual_machine_id = azurerm_windows_virtual_machine.vm.id
  publisher = "Microsoft.Compute"
  type = "CustomScriptExtension"
  type_handler_version = "1.10"

  settings = <<SETTINGS
  {
    "commandToExecute": "powershell -command \"Get-NetFirewallRule -Name FPS-ICMP*-ERQ-IN* | Enable-NetFirewallRule\""
  }
  SETTINGS
}
