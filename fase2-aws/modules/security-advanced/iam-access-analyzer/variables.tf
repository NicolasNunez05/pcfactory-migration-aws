# =============================================================================
# VARIABLES - IAM ACCESS ANALYZER
# =============================================================================
# Análisis continuo de permisos IAM y acceso a recursos
# Proyecto: PCFactory Migration AWS - Capstone DuocUC 2025
# =============================================================================

variable "project_name" {
  description = "Nombre del proyecto"
  type        = string
}

variable "environment" {
  description = "Ambiente (dev, staging, prod)"
  type        = string
}

variable "analyzer_name" {
  description = "Nombre del analizador"
  type        = string
  default     = null
}

variable "analyzer_type" {
  description = "Tipo de analizador: ACCOUNT o ORGANIZATION"
  type        = string
  default     = "ACCOUNT"
  validation {
    condition     = contains(["ACCOUNT", "ORGANIZATION"], var.analyzer_type)
    error_message = "analyzer_type debe ser ACCOUNT u ORGANIZATION"
  }
}

variable "enable_unused_access" {
  description = "Habilitar análisis de acceso no utilizado"
  type        = bool
  default     = true
}

variable "unused_access_age_days" {
  description = "Días para considerar acceso como no utilizado"
  type        = number
  default     = 90
}

variable "tags" {
  description = "Tags adicionales"
  type        = map(string)
  default     = {}
}
