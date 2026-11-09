# =============================================================================
# MÓDULO DE SEGURIDAD: FIREWALLS PERIMETRALES (NSG) Y SECRETOS (seguridad.tf)
# Análogo a plantillas/seguridad.yaml en CloudFormation
# =============================================================================

# 1. Generación de JWT_SECRET criptográficamente seguro
resource "random_password" "jwt_secret" {
  length  = 64
  special = false
}

# 2. Generación de contraseña aleatoria segura para PostgreSQL
resource "random_password" "db_password" {
  length  = 24
  special = false
}

# -----------------------------------------------------------------------------
# FIREWALL (NSG) - DATABASE (PostgreSQL)
# -----------------------------------------------------------------------------
resource "azurerm_network_security_group" "nsg_database" {
  name                = "nsg-${local.name_prefix}-database"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = local.common_tags

  # Permite administración remota vía SSH para Ansible
  security_rule {
    name                       = "Allow-SSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # Permite acceso al puerto 5432 EXCLUSIVAMENTE desde la subred del Backend
  security_rule {
    name                       = "Allow-Postgres-From-Backend"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = tostring(var.db_port)
    source_address_prefix      = azurerm_subnet.subnet_backend.address_prefixes[0]
    destination_address_prefix = "*"
  }

  # Bloqueo explícito del puerto 5432 desde Internet
  security_rule {
    name                       = "Deny-Postgres-Internet"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = tostring(var.db_port)
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }
}

# Asociación NSG Database a la interfaz de red
resource "azurerm_network_interface_security_group_association" "nic_nsg_database" {
  network_interface_id      = azurerm_network_interface.nic_database.id
  network_security_group_id = azurerm_network_security_group.nsg_database.id
}

# -----------------------------------------------------------------------------
# FIREWALL (NSG) - BACKEND
# -----------------------------------------------------------------------------
resource "azurerm_network_security_group" "nsg_backend" {
  name                = "nsg-${local.name_prefix}-backend"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = local.common_tags

  # Permite administración remota vía SSH
  security_rule {
    name                       = "Allow-SSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # Permite acceso a la API REST NestJS
  security_rule {
    name                       = "Allow-Backend-HTTP"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = tostring(var.backend_port)
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Asociación NSG Backend a la interfaz de red
resource "azurerm_network_interface_security_group_association" "nic_nsg_backend" {
  network_interface_id      = azurerm_network_interface.nic_backend.id
  network_security_group_id = azurerm_network_security_group.nsg_backend.id
}

# -----------------------------------------------------------------------------
# FIREWALL (NSG) - FRONTEND
# -----------------------------------------------------------------------------
resource "azurerm_network_security_group" "nsg_frontend" {
  name                = "nsg-${local.name_prefix}-frontend"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = local.common_tags

  # Permite administración remota vía SSH
  security_rule {
    name                       = "Allow-SSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # Permite tráfico HTTP (puerto 80) para el servidor Nginx
  security_rule {
    name                       = "Allow-Frontend-HTTP"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # Permite tráfico HTTPS (puerto 443) para TLS/SSL
  security_rule {
    name                       = "Allow-Frontend-HTTPS"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Asociación NSG Frontend a la interfaz de red
resource "azurerm_network_interface_security_group_association" "nic_nsg_frontend" {
  network_interface_id      = azurerm_network_interface.nic_frontend.id
  network_security_group_id = azurerm_network_security_group.nsg_frontend.id
}
