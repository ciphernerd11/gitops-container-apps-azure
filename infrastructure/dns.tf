resource "azurerm_dns_zone" "main" {
  name                = "disaster-relief.com"
  resource_group_name = azurerm_resource_group.main.name
  tags                = local.common_tags
}

# Note: The A record will be added once we have the Application Gateway Public IP.
# If using the managed AGIC addon, the IP is created automatically.
# We might need to use a data source or the 'azurerm_public_ip' resource if we manage it.
