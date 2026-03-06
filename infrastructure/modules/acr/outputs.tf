output "id" {
  description = "The ID of the Container Registry"
  value       = azurerm_container_registry.acr.id
}

output "login_server" {
  description = "The URL of the Container Registry"
  value       = azurerm_container_registry.acr.login_server
}
