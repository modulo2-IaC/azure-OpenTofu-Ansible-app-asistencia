# =============================================================================
# OUTPUTS - PROYECTO UNIFICADO (BACKEND + FRONTEND)
# Responsabilidad: Resumen claro de endpoints, accesos y comandos operativos
# =============================================================================

output "resource_group_name" {
  description = "Nombre del Resource Group que contiene toda la infraestructura"
  value       = azurerm_resource_group.rg.name
}

# -----------------------------------------------------------------------------
# BACKEND OUTPUTS
# -----------------------------------------------------------------------------
output "backend_public_ip" {
  description = "Dirección IP pública estática de la VM del Backend"
  value       = azurerm_public_ip.pip_backend.ip_address
}

output "backend_fqdn" {
  description = "FQDN de Azure asignado al Backend"
  value       = azurerm_public_ip.pip_backend.fqdn
}

output "backend_api_url" {
  description = "URL base de la API REST del Backend (puerto 3000)"
  value       = "http://${azurerm_public_ip.pip_backend.fqdn}:3000"
}

output "swagger_docs_url" {
  description = "URL interactiva de la documentación Swagger OpenAPI"
  value       = "http://${azurerm_public_ip.pip_backend.fqdn}:3000/api/docs"
}

output "ssh_command_backend" {
  description = "Comando SSH para conectarse a la máquina virtual del Backend"
  value       = "ssh -i ${var.ssh_private_key_path} ${var.admin_username}@${azurerm_public_ip.pip_backend.ip_address}"
}

# -----------------------------------------------------------------------------
# FRONTEND OUTPUTS
# -----------------------------------------------------------------------------
output "frontend_public_ip" {
  description = "Dirección IP pública estática de la VM del Frontend"
  value       = azurerm_public_ip.pip_frontend.ip_address
}

output "frontend_fqdn" {
  description = "FQDN de Azure asignado al Frontend"
  value       = azurerm_public_ip.pip_frontend.fqdn
}

output "frontend_url" {
  description = "URL principal para acceder a la aplicación web (FQDN / Nginx)"
  value       = "http://${azurerm_public_ip.pip_frontend.fqdn}"
}

output "frontend_ip_url" {
  description = "URL directa por IP pública de la aplicación web"
  value       = "http://${azurerm_public_ip.pip_frontend.ip_address}"
}

output "ssh_command_frontend" {
  description = "Comando SSH para conectarse a la máquina virtual del Frontend"
  value       = "ssh -i ${var.ssh_private_key_path} ${var.admin_username}@${azurerm_public_ip.pip_frontend.ip_address}"
}

# -----------------------------------------------------------------------------
# RESUMEN DE CREDENCIALES INICIALES
# -----------------------------------------------------------------------------
output "credentials_summary" {
  description = "Credenciales predeterminadas para iniciar sesión en la aplicación web"
  sensitive   = true
  value = {
    admin_login = {
      matricula = var.admin_registration_no
      password  = var.admin_initial_password
      rol       = "Administrador"
    }
    demo_student_login = {
      matricula = "12345600"
      password  = "12345600"
      rol       = "Estudiante"
    }
    note = "Infraestructura cloud lista. Ejecuta Ansible desde hardware/ansible (.//run-ansible.ps1 deploy) para configurar el software."
  }
}
