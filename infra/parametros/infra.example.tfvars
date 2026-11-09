# =============================================================================
# EJEMPLO DE PARÁMETROS: INFRAESTRUCTURA GENERAL (infra.example.tfvars)
# =============================================================================

project_name = "asistencia"
environment  = "dev"
location     = "swedencentral"

admin_username       = "azureuser"
ssh_public_key_path  = "~/.ssh/asistencia_vm.pub"
ssh_private_key_path = "~/.ssh/asistencia_vm"

alert_email = "admin@empresa.com"

extra_tags = {
  ManagedBy = "OpenTofu"
  Modulo    = "Hardware"
}
