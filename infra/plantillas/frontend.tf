# =============================================================================
# MÓDULO DE CÓMPUTO: FRONTEND REACT + VITE + NGINX (frontend.tf)
# Aprovisionamiento declarativo con Cloud-Init, write_files y filebase64
# =============================================================================

locals {
  carpeta_app_frontend = "${path.module}/../../../../asistencia-front"

  # Carga declarativa de archivos con filebase64 y fallback seguro
  frontend_package_json = fileexists("${local.carpeta_app_frontend}/package.json") ? filebase64("${local.carpeta_app_frontend}/package.json") : base64encode("{\n  \"name\": \"asistencia-front\",\n  \"version\": \"1.0.0\"\n}")
  frontend_index_html   = fileexists("${local.carpeta_app_frontend}/index.html") ? filebase64("${local.carpeta_app_frontend}/index.html") : base64encode("<!DOCTYPE html><html><head><title>Asistencia</title></head><body><div id=\"root\"></div></body></html>")
}

resource "azurerm_linux_virtual_machine" "frontend_vm" {
  name                = local.vm_frontend_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  size                = var.frontend_vm_size
  admin_username      = var.admin_username
  tags                = local.common_tags

  # Autenticación del administrador
  admin_password                  = var.admin_password
  disable_password_authentication = false

  # Tarjeta de red dedicada para Frontend
  network_interface_ids = [azurerm_network_interface.nic_frontend.id]

  # Disco del Sistema Operativo optimizado para Azure Free Tier
  os_disk {
    name                 = "osdisk-${local.name_prefix}-frontend"
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
  custom_data = base64encode(templatefile("${path.module}/cloud-init-frontend.yaml", {
    package_json   = local.frontend_package_json
    index_html     = local.frontend_index_html
    ambiente       = var.environment
    admin_username = var.admin_username
    node_version   = var.node_version
    backend_host   = azurerm_public_ip.pip_backend.ip_address
    vite_api_url   = var.vite_api_url
    repo_url       = var.frontend_repo_url
    repo_branch    = var.frontend_repo_branch
  }))

  # Garantiza que el backend y su IP pública se creen previamente
  depends_on = [azurerm_linux_virtual_machine.backend_vm]
}
