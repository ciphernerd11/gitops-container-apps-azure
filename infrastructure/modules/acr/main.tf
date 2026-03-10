resource "azurerm_container_registry" "acr" {
  name                = replace("acr${var.resource_prefix}", "-", "")
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = var.acr_sku
  admin_enabled       = false

  tags = merge(var.tags, { Name = replace("acr${var.resource_prefix}", "-", "") })
}
