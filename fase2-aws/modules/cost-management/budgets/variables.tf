# =============================================================================
# VARIABLES - MÓDULO AWS BUDGETS
# =============================================================================
# Configuración de presupuestos y alertas de costos
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

# -----------------------------------------------------------------------------
# PRESUPUESTO GLOBAL
# -----------------------------------------------------------------------------

variable "global_monthly_budget" {
  description = "Presupuesto mensual global en USD"
  type        = number
  default     = 50
}

variable "alert_threshold_percentage" {
  description = "Porcentaje de presupuesto para activar alerta"
  type        = number
  default     = 80
}

# -----------------------------------------------------------------------------
# PRESUPUESTOS POR SERVICIO
# -----------------------------------------------------------------------------

variable "enable_service_budgets" {
  description = "Habilitar presupuestos separados por servicio"
  type        = bool
  default     = true
}

variable "ec2_monthly_budget" {
  description = "Presupuesto mensual para EC2 en USD"
  type        = number
  default     = 20
}

variable "rds_monthly_budget" {
  description = "Presupuesto mensual para RDS en USD"
  type        = number
  default     = 10
}

variable "s3_monthly_budget" {
  description = "Presupuesto mensual para S3 en USD"
  type        = number
  default     = 5
}

variable "elasticache_monthly_budget" {
  description = "Presupuesto mensual para ElastiCache en USD"
  type        = number
  default     = 10
}

variable "other_services_budget" {
  description = "Presupuesto mensual para otros servicios en USD"
  type        = number
  default     = 5
}

# -----------------------------------------------------------------------------
# NOTIFICACIONES
# -----------------------------------------------------------------------------

variable "notification_emails" {
  description = "Lista de emails para recibir alertas de presupuesto"
  type        = list(string)
  default     = []
}

variable "sns_topic_arn" {
  description = "ARN del SNS topic para notificaciones (opcional)"
  type        = string
  default     = null
}

# -----------------------------------------------------------------------------
# CONFIGURACIÓN AVANZADA
# -----------------------------------------------------------------------------

variable "notification_type" {
  description = "Tipo de notificación: ACTUAL o FORECASTED"
  type        = string
  default     = "ACTUAL"
  validation {
    condition     = contains(["ACTUAL", "FORECASTED"], var.notification_type)
    error_message = "notification_type debe ser ACTUAL o FORECASTED"
  }
}

variable "comparison_operator" {
  description = "Operador de comparación: GREATER_THAN, LESS_THAN, EQUAL_TO"
  type        = string
  default     = "GREATER_THAN"
  validation {
    condition     = contains(["GREATER_THAN", "LESS_THAN", "EQUAL_TO"], var.comparison_operator)
    error_message = "comparison_operator debe ser GREATER_THAN, LESS_THAN o EQUAL_TO"
  }
}

variable "time_unit" {
  description = "Unidad de tiempo: MONTHLY, QUARTERLY, ANNUALLY"
  type        = string
  default     = "MONTHLY"
  validation {
    condition     = contains(["MONTHLY", "QUARTERLY", "ANNUALLY"], var.time_unit)
    error_message = "time_unit debe ser MONTHLY, QUARTERLY o ANNUALLY"
  }
}

# -----------------------------------------------------------------------------
# TAGS
# -----------------------------------------------------------------------------

variable "tags" {
  description = "Tags adicionales para recursos"
  type        = map(string)
  default     = {}
}
