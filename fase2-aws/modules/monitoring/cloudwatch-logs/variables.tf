variable "project_name" {
  description = "Nombre del proyecto"
  type        = string
}

variable "environment" {
  description = "Ambiente (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "retention_days_centralized" {
  description = "Días de retención para logs centralizados (compliance)"
  type        = number
  default     = 90
}

variable "retention_days_security" {
  description = "Días de retención para logs de seguridad (alta retención)"
  type        = number
  default     = 365
}

variable "enable_encryption" {
  description = "Habilitar encriptación KMS de logs"
  type        = bool
  default     = false  # Activar en prod
}

variable "enable_s3_export" {
  description = "Habilitar exportación automática a S3"
  type        = bool
  default     = false  # Implementar después
}
