# =============================================================================
# GENERADOR AUTOMÁTICO DE INVENTARIO PARA ANSIBLE (ansible_inventory.tf)
# Escribe dinámicamente las IPs públicas de Azure en ansible/inventory/hosts.ini
# Autenticación exclusiva por clave privada SSH
# =============================================================================

resource "local_file" "ansible_inventory" {
  filename        = "${path.module}/../../ansible/inventory/hosts.ini"
  file_permission = "0644"

  content = <<-EOT
# =============================================================================
# INVENTARIO GENERADO AUTOMÁTICAMENTE POR OPENTOFU
# Autenticación: Clave privada SSH
# =============================================================================

[backend]
vm-backend ansible_host=${azurerm_public_ip.pip_backend.ip_address} ansible_user=${var.admin_username} ansible_ssh_private_key_file=${var.ssh_private_key_path}

[frontend]
vm-frontend ansible_host=${azurerm_public_ip.pip_frontend.ip_address} ansible_user=${var.admin_username} ansible_ssh_private_key_file=${var.ssh_private_key_path}

[backend:vars]
jwt_secret=${coalesce(var.jwt_secret, random_password.jwt_secret.result)}
backend_host=${azurerm_public_ip.pip_backend.ip_address}

[frontend:vars]
backend_host=${azurerm_public_ip.pip_backend.ip_address}

[app:children]
backend
frontend

[all:vars]
ansible_python_interpreter=/usr/bin/python3
ansible_ssh_common_args='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o IdentitiesOnly=yes'
EOT
}
