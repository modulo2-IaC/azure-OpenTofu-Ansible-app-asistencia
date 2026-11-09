# =============================================================================
# MÓDULO DE CÓMPUTO: FRONTEND (frontend.tf)
# Aprovisionamiento de infraestructura base (VM Linux) para gestión con Ansible
# =============================================================================

resource "azurerm_linux_virtual_machine" "frontend_vm" {
  name                = local.vm_frontend_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  size                = var.frontend_vm_size
  admin_username      = var.admin_username
  tags                = local.common_tags

  # Autenticación exclusiva por clave SSH (deshabilita contraseñas)
  disable_password_authentication = true

  admin_ssh_key {
    username   = var.admin_username
    public_key = local.ssh_public_key
  }

  # Tarjeta de red dedicada para Frontend
  network_interface_ids = [azurerm_network_interface.nic_frontend.id]

  # Controlador de disco NVMe requerido para la serie v7 (Standard_F1as_v7)
  disk_controller_type = "NVMe"

  # Disco del Sistema Operativo
  os_disk {
    name                 = "osdisk-${local.name_prefix}-frontend"
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
    disk_size_gb         = 30
  }

  # Garantiza liberar cuota de vCPU antes de crear la nueva instancia
  lifecycle {
    create_before_destroy = false
  }

  # Imagen oficial Canonical Ubuntu 22.04 LTS (Jammy)
  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  # Garantiza que el backend y su IP pública se creen previamente
  depends_on = [azurerm_linux_virtual_machine.backend_vm]
}
