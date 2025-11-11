# =============================================================================
# VARIABLES - GUARDDUTY CON S3 PROTECTION
# =============================================================================
# Detección inteligente de amenazas con protección S3
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

variable "enable_s3_protection" {
  description = "Habilitar protección de S3"
  type        = bool
  default     = true
}

variable "enable_kubernetes_protection" {
  description = "Habilitar protección de Kubernetes (EKS)"
  type        = bool
  default     = false
}

variable "enable_malware_protection" {
  description = "Habilitar protección contra malware"
  type        = bool
  default     = true
}

variable "enable_runtime_monitoring" {
  description = "Habilitar monitoreo de runtime (EC2/ECS)"
  type        = bool
  default     = true
}

variable "finding_publishing_frequency" {
  description = "Frecuencia de publicación de hallazgos: FIFTEEN_MINUTES, ONE_HOUR, SIX_HOURS"
  type        = string
  default     = "FIFTEEN_MINUTES"
  validation {
    condition = contains([
      "FIFTEEN_MINUTES",
      "ONE_HOUR",
      "SIX_HOURS"
    ], var.finding_publishing_frequency)
    error_message = "finding_publishing_frequency debe ser FIFTEEN_MINUTES, ONE_HOUR o SIX_HOURS"
  }
}

variable "sns_topic_arn" {
  description = "ARN del SNS topic para notificaciones de GuardDuty"
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags adicionales"
  type        = map(string)
  default     = {}
}
