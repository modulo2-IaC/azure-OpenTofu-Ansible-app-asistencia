# =============================================================================
# PLANTILLA PRINCIPAL: ORQUESTACIÓN GENERAL Y RECURSOS BASE
# Sistema de Asistencia - Microsoft Azure con OpenTofu
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

  name_prefix        = "${var.project_name}-${var.environment}"
  rg_name            = "rg-${local.name_prefix}-${random_string.suffix.result}"
  vm_backend_name    = "vm-${local.name_prefix}-back-${random_string.suffix.result}"
  vm_frontend_name   = "vm-${local.name_prefix}-front-${random_string.suffix.result}"
  dns_backend_label  = "api-${local.name_prefix}-${random_string.suffix.result}"
  dns_frontend_label = "app-${local.name_prefix}-${random_string.suffix.result}"
}

# 1. Sufijo aleatorio para garantizar unicidad global en FQDNs y recursos de Azure
resource "random_string" "suffix" {
  length  = 5
  special = false
  upper   = false
}

# 2. Grupo de Recursos principal unificado para Backend y Frontend
resource "azurerm_resource_group" "rg" {
  name     = local.rg_name
  location = var.location
  tags     = local.common_tags
}
