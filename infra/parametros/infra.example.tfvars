# =============================================================================
# EJEMPLO DE PARÁMETROS: INFRAESTRUCTURA GENERAL (infra.example.tfvars)
# =============================================================================

project_name = "asistencia"
environment  = "dev"
location     = "swedencentral"

admin_username = "azureuser"
admin_password = "TuPasswordSeguro123!"

alert_email = "admin@empresa.com"

extra_tags = {
  ManagedBy = "OpenTofu"
  Modulo    = "Hardware"
}
