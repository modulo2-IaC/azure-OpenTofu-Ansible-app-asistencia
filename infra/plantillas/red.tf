# =============================================================================
# MÓDULO DE RED: TOPOLOGÍA, SUBREDES, IPS PÚBLICAS Y NICS (red.tf)
# Análogo a plantillas/red.yaml en CloudFormation
# =============================================================================

# 1. Red Virtual (VNet) compartida para la solución
resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-${local.name_prefix}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.0.0.0/16"]
  tags                = local.common_tags
}

# 2. Subred dedicada para la VM del Backend (10.0.1.0/24)
resource "azurerm_subnet" "subnet_backend" {
  name                 = "subnet-backend"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# 3. Subred dedicada para la VM del Frontend (10.0.2.0/24)
resource "azurerm_subnet" "subnet_frontend" {
  name                 = "subnet-frontend"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}

# 4. Subred dedicada para la VM de Base de Datos PostgreSQL (10.0.3.0/24)
resource "azurerm_subnet" "subnet_database" {
  name                 = "subnet-database"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.3.0/24"]
}

# 5. IP Pública para la VM de la Base de Datos (acceso SSH para aprovisionamiento con Ansible)
resource "azurerm_public_ip" "pip_database" {
  name                = "pip-${local.name_prefix}-database"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
  domain_name_label   = local.dns_database_label
  tags                = local.common_tags
}

# 6. IP Pública para la VM del Backend (Standard SKU compatible con Free Trial)
resource "azurerm_public_ip" "pip_backend" {
  name                = "pip-${local.name_prefix}-backend"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
  domain_name_label   = local.dns_backend_label
  tags                = local.common_tags
}

# 7. IP Pública para la VM del Frontend (Standard SKU)
resource "azurerm_public_ip" "pip_frontend" {
  name                = "pip-${local.name_prefix}-frontend"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
  domain_name_label   = local.dns_frontend_label
  tags                = local.common_tags
}

# 8. Tarjeta de Red Virtual (NIC) para la Base de Datos
resource "azurerm_network_interface" "nic_database" {
  name                = "nic-${local.name_prefix}-database"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = local.common_tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet_database.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip_database.id
  }
}

# 9. Tarjeta de Red Virtual (NIC) para el Backend
resource "azurerm_network_interface" "nic_backend" {
  name                = "nic-${local.name_prefix}-backend"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = local.common_tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet_backend.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip_backend.id
  }
}

# 10. Tarjeta de Red Virtual (NIC) para el Frontend
resource "azurerm_network_interface" "nic_frontend" {
  name                = "nic-${local.name_prefix}-frontend"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = local.common_tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet_frontend.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip_frontend.id
  }
}
