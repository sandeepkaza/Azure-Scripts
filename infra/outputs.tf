output "RESOURCE_GROUP_ID" {
  value = azurerm_resource_group.rg.id
}

output "AZURE_CONTAINER_REGISTRY_ENDPOINT" {
  value = azurerm_container_registry.acr.login_server
}

output "CONTAINER_APP_URL" {
  value = azurerm_container_app.ca.latest_revision_fqdn
}
