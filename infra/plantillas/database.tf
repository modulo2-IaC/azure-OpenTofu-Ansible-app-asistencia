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

  # Tarjeta de red dedicada para Base de Datos
  network_interface_ids = [azurerm_network_interface.nic_database.id]

  # Disco del Sistema Operativo optimizado para Azure Free Tier
  os_disk {
    name                 = "osdisk-${local.name_prefix}-database"
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
}
