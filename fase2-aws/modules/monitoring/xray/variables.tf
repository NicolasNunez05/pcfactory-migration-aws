variable "project_name" {
  description = "Nombre del proyecto"
  type        = string
}

variable "environment" {
  description = "Ambiente (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "enable_xray_insights" {
  description = "Habilitar X-Ray Insights (análisis avanzado, costo adicional)"
  type        = bool
  default     = false
}

variable "enable_xray_alarms" {
  description = "Habilitar alarmas basadas en métricas de X-Ray"
  type        = bool
  default     = true
}

variable "sns_topic_critical_arn" {
  description = "ARN del SNS topic para alarmas críticas"
  type        = string
  default     = ""
}

variable "sns_topic_warning_arn" {
  description = "ARN del SNS topic para alarmas de advertencia"
  type        = string
  default     = ""
}

variable "default_sampling_rate" {
  description = "Porcentaje de requests a capturar (0.0 - 1.0)"
  type        = number
  default     = 0.05  # 5%
  validation {
    condition     = var.default_sampling_rate >= 0 && var.default_sampling_rate <= 1
    error_message = "Sampling rate debe estar entre 0.0 y 1.0"
  }
}
