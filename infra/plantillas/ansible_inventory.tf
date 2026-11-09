# =============================================================================
# GENERADOR AUTOMÁTICO DE INVENTARIO PARA ANSIBLE (ansible_inventory.tf)
# Escribe dinámicamente las IPs de Azure en ansible/inventory/hosts.ini
# Arquitectura 3-Tier: Database (PostgreSQL), Backend (NestJS), Frontend (Vite)
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

[database]
vm-database ansible_host=${azurerm_public_ip.pip_database.ip_address} ansible_user=${var.admin_username} ansible_ssh_private_key_file=${var.ssh_private_key_path}

[backend]
vm-backend ansible_host=${azurerm_public_ip.pip_backend.ip_address} ansible_user=${var.admin_username} ansible_ssh_private_key_file=${var.ssh_private_key_path}

[frontend]
vm-frontend ansible_host=${azurerm_public_ip.pip_frontend.ip_address} ansible_user=${var.admin_username} ansible_ssh_private_key_file=${var.ssh_private_key_path}

[database:vars]
db_name=${var.db_name}
db_username=${var.db_username}
db_password=${coalesce(var.db_password, random_password.db_password.result)}
db_port=${var.db_port}
allowed_cidr=${azurerm_subnet.subnet_backend.address_prefixes[0]}

[backend:vars]
jwt_secret=${coalesce(var.jwt_secret, random_password.jwt_secret.result)}
backend_host=${azurerm_public_ip.pip_backend.ip_address}
database_url=${coalesce(var.database_url, "postgresql://${var.db_username}:${coalesce(var.db_password, random_password.db_password.result)}@${azurerm_network_interface.nic_database.private_ip_address}:${var.db_port}/${var.db_name}?sslmode=disable")}

[frontend:vars]
backend_host=${azurerm_public_ip.pip_backend.ip_address}

[app:children]
database
backend
frontend

[all:vars]
ansible_python_interpreter=/usr/bin/python3
ansible_ssh_common_args='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o IdentitiesOnly=yes'
EOT
}
