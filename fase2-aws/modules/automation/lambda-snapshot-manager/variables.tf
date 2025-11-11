variable "project_name" {
  description = "Nombre del proyecto"
  type        = string
}

variable "environment" {
  description = "Ambiente"
  type        = string
  default     = "dev"
}

variable "notification_topic_arn" {
  description = "ARN del SNS topic para notificaciones"
  type        = string
}

variable "sns_topic_critical_arn" {
  description = "ARN del SNS topic para alarmas críticas"
  type        = string
}

variable "retention_days" {
  description = "Días de retención de snapshots"
  type        = number
  default     = 7
}

variable "schedule_expression" {
  description = "Expresión cron/rate para programar ejecución"
  type        = string
  default     = "cron(0 2 * * ? *)"  # 2 AM todos los días (UTC)
  
  # Ejemplos:
  # "rate(1 day)"           - Cada 24 horas
  # "cron(0 2 * * ? *)"     - 2 AM diario
  # "cron(0 0 * * SUN *)"   - Domingo a medianoche
}
