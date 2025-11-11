variable "project_name" {
  description = "Nombre del proyecto"
  type        = string
}

variable "environment" {
  description = "Ambiente"
  type        = string
  default     = "dev"
}

variable "source_log_group_name" {
  description = "Nombre del log group fuente a parsear"
  type        = string
}

variable "source_log_group_arn" {
  description = "ARN del log group fuente"
  type        = string
}

variable "filter_pattern" {
  description = "Patrón de filtro para CloudWatch Logs"
  type        = string
  default     = ""  # "" = todos los logs
}

variable "sns_topic_warning_arn" {
  description = "ARN del SNS topic para alarmas"
  type        = string
}
