# =============================================================================
# VARIABLES - AWS CONFIG RULES
# =============================================================================
# Compliance y auditoría continua de recursos
# =============================================================================

variable "project_name" {
  description = "Nombre del proyecto"
  type        = string
}

variable "environment" {
  description = "Ambiente"
  type        = string
}

variable "s3_bucket_name" {
  description = "Bucket S3 para almacenar logs de Config"
  type        = string
}

variable "sns_topic_arn" {
  description = "ARN del SNS topic para notificaciones"
  type        = string
  default     = null
}

variable "enable_managed_rules" {
  description = "Habilitar reglas administradas de AWS"
  type        = bool
  default     = true
}

variable "recording_frequency" {
  description = "Frecuencia de grabación: CONTINUOUS o DAILY"
  type        = string
  default     = "CONTINUOUS"
}

variable "enable_all_supported" {
  description = "Grabar todos los recursos soportados"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags adicionales"
  type        = map(string)
  default     = {}
}

variable "enable_iam_password_policy" {
  description = "Enable IAM Password Policy Config Rule"
  type        = bool
  default     = true
}
