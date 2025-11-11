variable "project_name" {
  description = "Nombre del proyecto"
  type        = string
}

variable "environment" {
  description = "Ambiente (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "vpc_id" {
  description = "ID de la VPC para Flow Logs"
  type        = string
}

variable "public_subnet_ids" {
  description = "IDs de subnets públicas para Flow Logs adicionales"
  type        = list(string)
  default     = []
}

variable "traffic_type" {
  description = "Tipo de tráfico a capturar"
  type        = string
  default     = "REJECT"  # ACCEPT, REJECT, or ALL
  validation {
    condition     = contains(["ACCEPT", "REJECT", "ALL"], var.traffic_type)
    error_message = "traffic_type debe ser ACCEPT, REJECT, o ALL"
  }
}

variable "retention_days" {
  description = "Días de retención para logs de VPC"
  type        = number
  default     = 30
}

variable "retention_days_subnets" {
  description = "Días de retención para logs de subnets"
  type        = number
  default     = 7
}

variable "enable_subnet_logs" {
  description = "Habilitar Flow Logs adicionales en subnets públicas"
  type        = bool
  default     = true
}

variable "enable_encryption" {
  description = "Habilitar encriptación KMS de logs"
  type        = bool
  default     = false
}

variable "kms_key_id" {
  description = "ID de KMS key para encriptar logs"
  type        = string
  default     = null
}

variable "custom_log_format" {
  description = "Usar formato de log personalizado"
  type        = bool
  default     = false
}

variable "log_format" {
  description = "Formato personalizado de Flow Logs"
  type        = string
  default     = "$${version} $${account-id} $${interface-id} $${srcaddr} $${dstaddr} $${srcport} $${dstport} $${protocol} $${packets} $${bytes} $${start} $${end} $${action} $${log-status}"
}

variable "sns_topic_critical_arn" {
  description = "ARN del SNS topic para alarmas críticas"
  type        = string
}

variable "sns_topic_warning_arn" {
  description = "ARN del SNS topic para alarmas de advertencia"
  type        = string
}
