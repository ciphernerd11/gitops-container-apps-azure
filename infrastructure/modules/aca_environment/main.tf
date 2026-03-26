variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "resource_prefix" {
  type = string
}

variable "log_analytics_workspace_id" {
  type = string
}

variable "vnet_subnet_id" {
  type = string
}

variable "tags" {
  type = map(string)
}

variable "app_insights_connection_string" {
  type    = string
  default = null
}

resource "azurerm_container_app_environment" "main" {
  name                       = "cae-${var.resource_prefix}"
  location                   = var.location
  resource_group_name        = var.resource_group_name
  log_analytics_workspace_id  = var.log_analytics_workspace_id
  infrastructure_subnet_id    = var.vnet_subnet_id
  internal_load_balancer_enabled = true # Keep it internal for privacy

  dapr_application_insights_connection_string = var.app_insights_connection_string

  tags = merge(var.tags, { Name = "cae-${var.resource_prefix}" })
}

output "id" {
  value = azurerm_container_app_environment.main.id
}

output "default_domain" {
  value = azurerm_container_app_environment.main.default_domain
}
