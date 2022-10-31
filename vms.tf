/*
locals {
  vms = { for vm in var.virtual_machines: vm.vm_name => vm }
  disks_list = distinct(flatten([
      for vm in local.vms :  [
        for disk in try(vm.disks, []) : {
          vm_name = vm.vm_name
          name = disk.name
          size_gb = disk.size_gb
          lun = disk.lun
          tier = disk.tier
          id = "${vm.vm_name}.${disk.name}"
        }
      ]
    ]))
  disks = { for disk in local.disks_list : disk.id => disk }
}

resource "azurerm_network_interface" "nic" {
  for_each = local.vms
  name = "${var.name_prefix}-${each.value.vm_name}-nic01"
  resource_group_name = azurerm_resource_group.rg.name
  location = azurerm_resource_group.rg.location

  ip_configuration {
    name = "internal"
    subnet_id = azurerm_subnet.subnets[each.value.subnet].id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_windows_virtual_machine" "vm" {
  for_each = local.vms
  name = "${var.name_prefix}-${each.value.vm_name}"
  computer_name = each.value.os_name
  resource_group_name = azurerm_resource_group.rg.name
  location = azurerm_resource_group.rg.location
  size = each.value.size
  admin_username = var.default_user
  admin_password = var.default_password

  network_interface_ids = [
    azurerm_network_interface.nic[each.key].id
  ]

  os_disk {
    caching = "ReadWrite"
    storage_account_type = "Premium_LRS"
    name = "${var.name_prefix}-${each.value.vm_name}-disk-os"
  }

  dynamic "source_image_reference" {
    for_each = try(each.value.use_mssql, false) ? [] : [1]

    content {
      publisher = "MicrosoftWindowsServer"
      offer = "WindowsServer"
      sku = "2016-Datacenter"
      version = "latest"
    }
  }

  dynamic "source_image_reference" {
    for_each = try(each.value.use_mssql, false) ? [1] : []

    content {
        publisher = "MicrosoftSQLServer"
        offer = "sql2019-ws2016"
        sku = "enterprise"
        version = "latest"
    }
  }

  boot_diagnostics {}
}

resource "azurerm_managed_disk" "datadisk" {
  for_each = local.disks
  name = "${azurerm_windows_virtual_machine.vm[each.value.vm_name].name}-disk-${each.value.name}"
  location = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  storage_account_type = each.value.tier
  create_option = "Empty"
  disk_size_gb = each.value.size_gb
}

resource "azurerm_virtual_machine_data_disk_attachment" "datadisk_attach" {
  for_each = local.disks
  managed_disk_id = azurerm_managed_disk.datadisk[each.key].id
  virtual_machine_id = azurerm_windows_virtual_machine.vm[each.value.vm_name].id
  lun = each.value.lun
  caching = "ReadWrite"
}

resource "azurerm_mssql_virtual_machine" "mssql" {
  for_each = {
    for vm in var.virtual_machines: vm.vm_name => vm
    if try(vm.use_mssql, false)
  }

  virtual_machine_id = azurerm_windows_virtual_machine.vm[each.key].id
  sql_license_type = "PAYG"
  sql_connectivity_update_password = var.default_password
  sql_connectivity_update_username = var.default_user

  storage_configuration {
    disk_type = "NEW"
    storage_workload_type = "OLTP"

    dynamic "data_settings" {
      for_each = lookup(each.value, "mssql_data_settings", null) == null ? [] : [each.value.mssql_data_settings] // if key exists, return it as single item to process
      iterator = settings

      content {
        luns = settings.value.luns
        default_file_path = settings.value.file_path
      }
    }

    dynamic "log_settings" {
      for_each = lookup(each.value, "mssql_log_settings", null) == null ? [] : [each.value.mssql_log_settings] // if key exists, return it as single item to process
      iterator = settings

      content {
        luns = settings.value.luns
        default_file_path = settings.value.file_path
      }
    }

    dynamic "temp_db_settings" {
      for_each = lookup(each.value, "mssql_temp_db_settings", null) == null ? [] : [each.value.mssql_temp_db_settings] // if key exists, return it as single item to process
      iterator = settings

      content {
        luns = settings.value.luns
        default_file_path = settings.value.file_path
      }
    }
  }
}

/*
resource "azurerm_virtual_machine_extension" "ping" {
  count = var.vm_count
  name = "EnablePing"
  virtual_machine_id = azurerm_windows_virtual_machine.vm[count.index].id
  publisher = "Microsoft.Compute"
  type = "CustomScriptExtension"
  type_handler_version = "1.9"

  settings = <<SETTINGS
  {
    "commandToExecute": "powershell -command \"Get-NetFirewallRule -Name FPS-ICMP*-ERQ-IN* | Enable-NetFirewallRule\""
  }
  SETTINGS
}
*/
// TODO:
/*
    1) explicit naming
    2) data drives optionally
    3) DB servers should be blocked from accesing internet directly (NSG)
    4) separate subnets
*/
