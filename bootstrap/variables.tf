variable "project_name" {
  description = "Nombre base del proyecto"
  type        = string
  default     = "asistencia"
}

variable "environment" {
  description = "Ambiente (shared, dev, prod)"
  type        = string
  default     = "shared"
}

variable "location" {
  description = "Region de Azure"
  type        = string
  default     = "swedencentral"
}

variable "resource_group_name" {
  description = "Nombre del Grupo de Recursos para el tfstate"
  type        = string
  default     = "rg-asistencia-tfstate"
}

variable "storage_account_name" {
  description = "Nombre de la cuenta de almacenamiento (globalmente unico, 3-24 caracteres en minusculas)"
  type        = string
  default     = "sttofuasistenciadev"
}

variable "container_name" {
  description = "Nombre del contenedor Blob para los estados de OpenTofu"
  type        = string
  default     = "tfstate"
}

variable "extra_tags" {
  description = "Etiquetas adicionales para los recursos"
  type        = map(string)
  default     = {}
}
