# =============================================================================
# VARIABLES DE CONFIGURACIÓN - PROYECTO UNIFICADO
# Responsabilidad: Parámetros tipados, seguros y desacoplados
# =============================================================================

variable "project_name" {
  description = "Nombre base del proyecto para nombramiento de recursos"
  type        = string
  default     = "asistencia"
}

variable "environment" {
  description = "Entorno de despliegue (dev, staging, prod)"
  type        = string
  default     = "prod"
}

variable "location" {
  description = "Región de Azure donde se desplegarán los recursos"
  type        = string
  default     = "eastus2"
}

variable "backend_vm_size" {
  description = "Tamaño de la máquina virtual del Backend"
  type        = string
  default     = "Standard_B1s"
}

variable "frontend_vm_size" {
  description = "Tamaño de la máquina virtual del Frontend"
  type        = string
  default     = "Standard_B1s"
}

variable "admin_username" {
  description = "Usuario administrador del sistema operativo en las máquinas virtuales"
  type        = string
  default     = "azureuser"
}

variable "admin_password" {
  description = "Contraseña para el usuario administrador de las máquinas virtuales"
  type        = string
  sensitive   = true
}

variable "admin_registration_no" {
  description = "Matrícula o número de registro del usuario Administrador del sistema"
  type        = string
  default     = "123456789"
}

variable "admin_initial_password" {
  description = "Contraseña inicial para el usuario Administrador del sistema"
  type        = string
  default     = "123456789"
  sensitive   = true
}

variable "admin_full_name" {
  description = "Nombre completo del Administrador en la base de datos"
  type        = string
  default     = "Administrador General"
}

variable "database_url" {
  description = "Cadena de conexión de PostgreSQL con sslmode=require"
  type        = string
  sensitive   = true
}

variable "jwt_secret" {
  description = "Secreto JWT para firmar tokens de autenticación (si está vacío, se auto-genera)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "cors_origin" {
  description = "Orígenes permitidos para solicitudes CORS en el backend"
  type        = string
  default     = ""
}

variable "app_timezone" {
  description = "Zona horaria configurada para la aplicación"
  type        = string
  default     = "America/La_Paz"
}

variable "run_migrations" {
  description = "Bandera booleana para ejecutar migraciones de base de datos en cloud-init"
  type        = bool
  default     = true
}

variable "node_version" {
  description = "Versión mayor de Node.js a instalar en las VMs"
  type        = string
  default     = "20"
}

variable "backend_repo_url" {
  description = "URL del repositorio Git de la aplicación Backend"
  type        = string
  default     = "https://github.com/mario-2001/app-asistencia-backend.git"
}

variable "backend_repo_branch" {
  description = "Rama del repositorio Git a desplegar en el Backend"
  type        = string
  default     = "dev"
}

variable "frontend_repo_url" {
  description = "URL del repositorio Git de la aplicación Frontend"
  type        = string
  default     = "https://github.com/mario-2001/app-asistencia-frontend.git"
}

variable "frontend_repo_branch" {
  description = "Rama del repositorio Git a desplegar en el Frontend"
  type        = string
  default     = "dev"
}

variable "backend_port" {
  description = "Puerto TCP en el que se ejecuta la aplicación Backend"
  type        = number
  default     = 3000
}

variable "vite_api_url" {
  description = "URL base de la API del backend inyectada al frontend (vacío = ruta relativa /api vía Nginx)"
  type        = string
  default     = ""
}

variable "alert_email" {
  description = "Correo electrónico del equipo de operaciones para recibir alertas de métricas"
  type        = string
  default     = "admin@empresa.com"
}

variable "extra_tags" {
  description = "Etiquetas adicionales para gobierno y gestión de costos"
  type        = map(string)
  default     = {}
}
