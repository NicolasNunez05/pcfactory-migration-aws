variable "project_name" {
  description = "Nombre del proyecto"
  type        = string
}

variable "environment" {
  description = "Ambiente"
  type        = string
  default     = "dev"
}

variable "alarm_topic_arn" {
  description = "ARN del SNS topic que recibe alarmas"
  type        = string
}

variable "notification_topic_arn" {
  description = "ARN del SNS topic para notificar acciones tomadas"
  type        = string
}
