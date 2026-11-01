# =============================================================================
# PROVEEDORES Y VERSIÓN - OPENTOFU (IaC.md Puntos 1, 3 y 4)
# Configuración del proveedor AzureRM y Backend de Estado Remoto
# =============================================================================

terraform {
  required_version = ">= 1.6.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.90"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }

  # Backend Remoto en Azure Blob Storage (creado previamente por bootstrap/)
  backend "azurerm" {
    resource_group_name  = "rg-asistencia-tfstate"
    storage_account_name = "sttofuasistenciadev"
    container_name       = "tfstate"
    key                  = "infra.terraform.tfstate"
  }
}

provider "azurerm" {
  features {}
}
