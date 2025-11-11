# =============================================================================
# VARIABLES - SYSTEMS MANAGER AUTOMATION
# =============================================================================
# Runbooks automatizados para tareas operativas
# =============================================================================

variable "project_name" {
  description = "Nombre del proyecto"
  type        = string
}

variable "environment" {
  description = "Ambiente"
  type        = string
}

variable "enable_backup_automation" {
  description = "Habilitar automatización de backups"
  type        = bool
  default     = true
}

variable "enable_patching_automation" {
  description = "Habilitar automatización de parches"
  type        = bool
  default     = true
}

variable "enable_snapshot_automation" {
  description = "Habilitar automatización de snapshots EBS"
  type        = bool
  default     = true
}

variable "backup_schedule" {
  description = "Expresión cron para backups"
  type        = string
  default     = "cron(0 2 * * ? *)"
}

variable "patching_schedule" {
  description = "Expresión cron para patching"
  type        = string
  default     = "cron(0 3 ? * SUN *)"
}

variable "snapshot_retention_days" {
  description = "Días de retención para snapshots"
  type        = number
  default     = 7
}

variable "sns_topic_arn" {
  description = "ARN del SNS topic para notificaciones"
  type        = string
}

variable "tags" {
  description = "Tags adicionales"
  type        = map(string)
  default     = {}
}
