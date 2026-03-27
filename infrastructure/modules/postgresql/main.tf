variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "resource_prefix" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "vnet_id" {
  type = string
}

variable "admin_username" {
  type    = string
  default = "psqladmin"
}

variable "admin_password" {
  type = string
}

variable "sku_name" {
  type    = string
  default = "B_Standard_B1ms" # Cheaper for dev
}

variable "storage_mb" {
  type    = number
  default = 32768
}

variable "tags" {
  type = map(string)
}

resource "azurerm_private_dns_zone" "psql" {
  name                = "${var.resource_prefix}.postgres.database.azure.com"
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "psql" {
  name                  = "psql-link-${var.resource_prefix}"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.psql.name
  virtual_network_id    = var.vnet_id
}

resource "azurerm_postgresql_flexible_server" "main" {
  name                   = "psql-${var.resource_prefix}-v2"
  resource_group_name    = var.resource_group_name
  location               = var.location
  zone                   = "1"
  version                = "16"
  delegated_subnet_id    = var.subnet_id
  private_dns_zone_id    = azurerm_private_dns_zone.psql.id
  administrator_login    = var.admin_username
  administrator_password = var.admin_password
  sku_name                      = var.sku_name
  storage_mb                    = var.storage_mb
  public_network_access_enabled = false

  depends_on = [azurerm_private_dns_zone_virtual_network_link.psql]

  tags = merge(var.tags, { Name = "psql-${var.resource_prefix}" })
}

resource "azurerm_postgresql_flexible_server_database" "main" {
  name      = "resources"
  server_id = azurerm_postgresql_flexible_server.main.id
  charset   = "UTF8"
  collation = "en_US.utf8"
}

output "id" {
  value = azurerm_postgresql_flexible_server.main.id
}

output "fqdn" {
  value = azurerm_postgresql_flexible_server.main.fqdn
}
