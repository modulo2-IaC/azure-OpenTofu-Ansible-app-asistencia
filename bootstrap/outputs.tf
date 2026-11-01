# =============================================================================
# BOOTSTRAP - OUTPUTS
# Exporta valores necesarios para configurar el backend remoto en infra/
# =============================================================================

output "resource_group_name" {
  description = "Nombre del Resource Group que contiene el Storage Account del estado remoto"
  value       = azurerm_resource_group.tfstate.name
}

output "storage_account_name" {
  description = "Nombre de la Cuenta de Almacenamiento para el backend remoto"
  value       = azurerm_storage_account.tfstate.name
}

output "container_name" {
  description = "Nombre del Contenedor Blob para los archivos .tfstate"
  value       = azurerm_storage_container.tfstate.name
}

output "backend_config_infra" {
  description = "Bloque de configuracion de backend remoto para el proyecto infra/"
  value       = <<EOT
backend "azurerm" {
  resource_group_name  = "${azurerm_resource_group.tfstate.name}"
  storage_account_name = "${azurerm_storage_account.tfstate.name}"
  container_name       = "${azurerm_storage_container.tfstate.name}"
  key                  = "infra.terraform.tfstate"
}
EOT
}
