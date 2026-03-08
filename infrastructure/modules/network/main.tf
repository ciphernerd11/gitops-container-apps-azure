resource "azurerm_virtual_network" "main" {
  name                = "vnet-${var.resource_prefix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = var.vnet_cidr
  tags                = var.tags
}

resource "azurerm_subnet" "app" {
  count                = length(var.app_subnets_cidr)
  name                 = "snet-app-${format("%02d", count.index + 1)}"
  virtual_network_name = azurerm_virtual_network.main.name
  resource_group_name  = var.resource_group_name
  address_prefixes     = [var.app_subnets_cidr[count.index]]
}

resource "azurerm_subnet" "db" {
  count                = length(var.db_subnets_cidr)
  name                 = "snet-db-${format("%02d", count.index + 1)}"
  virtual_network_name = azurerm_virtual_network.main.name
  resource_group_name  = var.resource_group_name
  address_prefixes     = [var.db_subnets_cidr[count.index]]
}

resource "azurerm_network_security_group" "app" {
  name                = "nsg-app-${var.resource_prefix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_network_security_group" "db" {
  name                = "nsg-db-${var.resource_prefix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_subnet_network_security_group_association" "app" {
  count                     = length(var.app_subnets_cidr)
  subnet_id                 = azurerm_subnet.app[count.index].id
  network_security_group_id = azurerm_network_security_group.app.id
}

resource "azurerm_subnet_network_security_group_association" "db" {
  count                     = length(var.db_subnets_cidr)
  subnet_id                 = azurerm_subnet.db[count.index].id
  network_security_group_id = azurerm_network_security_group.db.id
}

resource "azurerm_network_security_rule" "allow_app_to_db" {
  name                        = "AllowAppToDB"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_ranges     = ["5432", "3306", "1433", "6379", "27017"] # Common DB ports
  source_address_prefixes     = var.app_subnets_cidr
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.db.name
}

resource "azurerm_network_security_rule" "deny_all_inbound_db" {
  name                        = "DenyAllInboundDB"
  priority                    = 4096
  direction                   = "Inbound"
  access                      = "Deny"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.db.name
}

resource "azurerm_network_security_rule" "allow_http" {
  name                        = "AllowHTTP"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "80"
  source_address_prefix       = "Internet"
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.app.name
}
