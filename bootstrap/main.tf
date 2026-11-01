# =============================================================================
# BOOTSTRAP - MAIN
# Responsabilidad: Orquestacion general, etiquetas comunes y Resource Group
# =============================================================================

locals {
  common_tags = merge(
    {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "OpenTofu"
    },
    var.extra_tags
  )
}

# 1. Grupo de Recursos para el almacenamiento del estado remoto
resource "azurerm_resource_group" "tfstate" {
  name     = var.resource_group_name
  location = var.location
  tags     = local.common_tags
}
