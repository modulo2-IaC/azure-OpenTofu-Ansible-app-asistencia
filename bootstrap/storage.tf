# =============================================================================
# BOOTSTRAP - STORAGE
# Responsabilidad: Alta cohesion para el almacenamiento de estados de OpenTofu
# =============================================================================

# 1. Cuenta de Almacenamiento Azure Storage Account
# Optimizada para el plan gratuito de Azure (Standard LRS, TLS 1.2, acceso publico denegado)
resource "azurerm_storage_account" "tfstate" {
  name                            = var.storage_account_name
  resource_group_name             = azurerm_resource_group.tfstate.name
  location                        = azurerm_resource_group.tfstate.location
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false

  blob_properties {
    versioning_enabled = true
    delete_retention_policy {
      days = 30
    }
  }

  tags = local.common_tags
}

# 2. Contenedor de Blobs para almacenar los archivos .tfstate
resource "azurerm_storage_container" "tfstate" {
  name                  = var.container_name
  storage_account_name  = azurerm_storage_account.tfstate.name
  container_access_type = "private"
}

