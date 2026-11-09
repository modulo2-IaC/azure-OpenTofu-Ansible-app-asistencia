# =============================================================================
# MÓDULO DE CÓMPUTO: BASE DE DATOS POSTGRESQL (database.tf)
# Aprovisionamiento de infraestructura base (VM Linux) para PostgreSQL
# =============================================================================

resource "azurerm_linux_virtual_machine" "database_vm" {
  name                = local.vm_database_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  size                = var.database_vm_size
  admin_username      = var.admin_username
  tags                = local.common_tags

  # Autenticación exclusiva por clave SSH (deshabilita contraseñas)
  disable_password_authentication = true

  admin_ssh_key {
    username   = var.admin_username
    public_key = local.ssh_public_key
  }

  # Dependencia explícita para asegurar que el resize de frontend_vm ocurra primero y libere cuota de vCPU
  depends_on = [azurerm_linux_virtual_machine.frontend_vm]

  # Tarjeta de red dedicada para Base de Datos
  network_interface_ids = [azurerm_network_interface.nic_database.id]

  # Controlador de disco NVMe requerido para la serie v7 (Standard_F1as_v7)
  disk_controller_type = "NVMe"

  # Disco del Sistema Operativo
  os_disk {
    name                 = "osdisk-${local.name_prefix}-database"
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
    disk_size_gb         = 30
  }

  # Imagen oficial Canonical Ubuntu 22.04 LTS (Jammy)
  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }
}
