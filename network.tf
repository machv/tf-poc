resource "azurerm_virtual_network" "hub" {
  name = "${var.name_prefix}-${var.network_name}"
  resource_group_name = azurerm_resource_group.rg.name
  location = azurerm_resource_group.rg.location
  address_space = var.address_space
}

resource "azurerm_subnet" "subnets" {
  for_each = {for subnet in var.subnets : subnet.name => subnet}
  name = each.value.name
  address_prefixes = each.value.address_prefixes
  virtual_network_name = azurerm_virtual_network.hub.name
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_network_security_group" "subnets" {
  for_each = {
    for subnet in var.subnets : subnet.name => subnet
    if length(subnet.rules) > 0
  }
  name = "${azurerm_virtual_network.hub.name}-${each.value.name}-nsg"
  location = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  dynamic "security_rule" {
    for_each = {
      for rule in each.value.rules : rule.name => rule 
    }

    content {
      name = security_rule.key
      direction = security_rule.value.direction
      access = security_rule.value.access
      priority = security_rule.value.priority
      protocol = security_rule.value.protocol
      source_port_range = security_rule.value.source_port_range
      destination_port_range = security_rule.value.destination_port_range
      source_address_prefix = security_rule.value.source_address_prefix
      destination_address_prefix = security_rule.value.destination_address_prefix
    }
  }
}

resource "azurerm_subnet_network_security_group_association" "nsg" {
  for_each = {
    for subnet in var.subnets : subnet.name => subnet
    if length(subnet.rules) > 0
  }

  subnet_id = azurerm_subnet.subnets[each.key].id
  network_security_group_id = azurerm_network_security_group.subnets[each.key].id
}

/* Bastion */
resource "azurerm_subnet" "bastion" {
  count = var.deploy_bastion ? 1 : 0
  name = "AzureBastionSubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes = [var.bastion_prefix]
}

resource "azurerm_public_ip" "bastion" {
  count = var.deploy_bastion ? 1 : 0
  name = "${var.name_prefix}-bastion-pip"
  location = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method = "Static"
  sku = "Standard"
}

resource "azurerm_bastion_host" "bastion" {
  count = var.deploy_bastion ? 1 : 0
  name = "${var.name_prefix}-bastion"
  location = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name = "configuration"
    subnet_id = azurerm_subnet.bastion[0].id
    public_ip_address_id = azurerm_public_ip.bastion[0].id
  }
}

