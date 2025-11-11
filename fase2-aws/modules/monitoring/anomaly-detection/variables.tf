# =============================================================================
# VARIABLES - CLOUDWATCH ANOMALY DETECTION
# =============================================================================
# Detección de anomalías en métricas clave
# =============================================================================

variable "project_name" {
  description = "Nombre del proyecto"
  type        = string
}

variable "environment" {
  description = "Ambiente"
  type        = string
}

variable "sns_topic_arn" {
  description = "ARN del SNS topic para alarmas"
  type        = string
}

variable "enable_cpu_anomaly" {
  description = "Habilitar detección de anomalías en CPU"
  type        = bool
  default     = true
}

variable "enable_db_anomaly" {
  description = "Habilitar detección de anomalías en DB"
  type        = bool
  default     = true
}

variable "enable_network_anomaly" {
  description = "Habilitar detección de anomalías en red"
  type        = bool
  default     = true
}

variable "enable_request_anomaly" {
  description = "Habilitar detección de anomalías en requests"
  type        = bool
  default     = true
}

variable "anomaly_band_width" {
  description = "Ancho de banda de anomalía (desviaciones estándar)"
  type        = number
  default     = 2
}

variable "evaluation_periods" {
  description = "Períodos de evaluación para alarmas"
  type        = number
  default     = 2
}

variable "tags" {
  description = "Tags adicionales"
  type        = map(string)
  default     = {}
}
