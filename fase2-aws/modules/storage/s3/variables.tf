# =============================================================================
# VARIABLES - MÓDULO S3 STORAGE
# =============================================================================
# Configuración de buckets S3 con versionado y lifecycle policies
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

variable "kms_key_id" {
  description = "ARN de la clave KMS para cifrado de buckets"
  type        = string
}

# -----------------------------------------------------------------------------
# CONFIGURACIÓN DE BUCKETS
# -----------------------------------------------------------------------------

variable "enable_backups_bucket" {
  description = "Habilitar bucket de backups"
  type        = bool
  default     = true
}

variable "enable_logs_bucket" {
  description = "Habilitar bucket de logs"
  type        = bool
  default     = true
}

variable "enable_artifacts_bucket" {
  description = "Habilitar bucket de artefactos CI/CD"
  type        = bool
  default     = true
}

# -----------------------------------------------------------------------------
# LIFECYCLE POLICIES - BACKUPS
# -----------------------------------------------------------------------------

variable "backups_standard_days" {
  description = "Días en STANDARD antes de transicionar a IA (backups)"
  type        = number
  default     = 30
}

variable "backups_ia_days" {
  description = "Días en STANDARD_IA antes de transicionar a GLACIER (backups)"
  type        = number
  default     = 90
}

variable "backups_glacier_days" {
  description = "Días en GLACIER antes de transicionar a DEEP_ARCHIVE (backups)"
  type        = number
  default     = 365
}

variable "backups_noncurrent_version_days" {
  description = "Días para retener versiones no actuales antes de eliminar (backups)"
  type        = number
  default     = 90
}

# -----------------------------------------------------------------------------
# LIFECYCLE POLICIES - LOGS
# -----------------------------------------------------------------------------

variable "logs_standard_days" {
  description = "Días en STANDARD antes de transicionar a IA (logs)"
  type        = number
  default     = 30
}

variable "logs_ia_days" {
  description = "Días en STANDARD_IA antes de eliminar (logs)"
  type        = number
  default     = 90
}

variable "logs_expiration_days" {
  description = "Días antes de eliminar logs completamente"
  type        = number
  default     = 90
}

# -----------------------------------------------------------------------------
# LIFECYCLE POLICIES - ARTIFACTS
# -----------------------------------------------------------------------------

variable "artifacts_standard_days" {
  description = "Días en STANDARD antes de transicionar a IA (artifacts)"
  type        = number
  default     = 60
}

variable "artifacts_ia_days" {
  description = "Días en STANDARD_IA antes de eliminar (artifacts)"
  type        = number
  default     = 180
}

variable "artifacts_noncurrent_version_days" {
  description = "Días para retener versiones no actuales antes de eliminar (artifacts)"
  type        = number
  default     = 60
}

# -----------------------------------------------------------------------------
# CONFIGURACIÓN GENERAL
# -----------------------------------------------------------------------------

variable "enable_mfa_delete" {
  description = "Habilitar MFA Delete en bucket de backups (requiere configuración manual después)"
  type        = bool
  default     = false
}

variable "incomplete_multipart_days" {
  description = "Días para eliminar uploads multiparte incompletos"
  type        = number
  default     = 7
}

variable "enable_access_logging" {
  description = "Habilitar logging de acceso a buckets"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags adicionales para recursos"
  type        = map(string)
  default     = {}
}

