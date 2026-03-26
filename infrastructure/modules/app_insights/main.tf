variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "resource_prefix" {
  type = string
}

variable "workspace_id" {
  type = string
}

variable "tags" {
  type = map(string)
}

resource "azurerm_application_insights" "main" {
  name                = "ai-${var.resource_prefix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  workspace_id        = var.workspace_id
  application_type    = "web"
  
  tags = merge(var.tags, { Name = "ai-${var.resource_prefix}" })
}

output "id" {
  value = azurerm_application_insights.main.id
}

output "connection_string" {
  value = azurerm_application_insights.main.connection_string
}

output "instrumentation_key" {
  value = azurerm_application_insights.main.instrumentation_key
}
