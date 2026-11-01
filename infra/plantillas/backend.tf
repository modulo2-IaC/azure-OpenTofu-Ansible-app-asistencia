# =============================================================================
# MÓDULO DE CÓMPUTO: BACKEND NESTJS + SYSTEMD (backend.tf)
# Aprovisionamiento declarativo con Cloud-Init, write_files y filebase64
# =============================================================================

locals {
  carpeta_app_backend = "${path.module}/../../../../asistencia-backend"

  # Carga de archivos con filebase64 y fallback seguro
  backend_package_json = fileexists("${local.carpeta_app_backend}/package.json") ? filebase64("${local.carpeta_app_backend}/package.json") : base64encode("{\n  \"name\": \"asistencia-backend\",\n  \"version\": \"1.0.0\"\n}")
}

resource "azurerm_linux_virtual_machine" "backend_vm" {
  name                = local.vm_backend_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  size                = var.backend_vm_size
  admin_username      = var.admin_username
  tags                = local.common_tags

  # Autenticación del administrador
  admin_password                  = var.admin_password
  disable_password_authentication = false

  # Tarjeta de red dedicada para Backend
  network_interface_ids = [azurerm_network_interface.nic_backend.id]

  # Disco del Sistema Operativo optimizado para Azure Free Tier
  os_disk {
    name                 = "osdisk-${local.name_prefix}-backend"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = 30
  }

  # Imagen oficial Canonical Ubuntu 22.04 LTS (Jammy)
  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  # Aprovisionamiento automatizado de inicio con Cloud-Init (write_files b64 + systemd)
  custom_data = base64encode(templatefile("${path.module}/cloud-init-backend.yaml", {
    package_json          = local.backend_package_json
    ambiente              = var.environment
    admin_username        = var.admin_username
    node_version          = var.node_version
    database_url          = var.database_url
    jwt_secret            = coalesce(var.jwt_secret, random_password.jwt_secret.result)
    cors_origin           = var.cors_origin
    app_timezone          = var.app_timezone
    run_migrations        = var.run_migrations ? "true" : "false"
    admin_registration_no = var.admin_registration_no
    admin_password        = var.admin_initial_password
    admin_full_name       = var.admin_full_name
    repo_url              = var.backend_repo_url
    repo_branch           = var.backend_repo_branch
  }))
}
