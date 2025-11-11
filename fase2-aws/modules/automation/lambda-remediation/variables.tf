# =============================================================================
# VARIABLES - LAMBDA AUTOMATED REMEDIATION
# =============================================================================
# Respuesta automática a hallazgos de seguridad
# =============================================================================

variable "project_name" {
  description = "Nombre del proyecto"
  type        = string
}

variable "environment" {
  description = "Ambiente"
  type        = string
}

variable "enable_sg_remediation" {
  description = "Habilitar remediación automática de security groups"
  type        = bool
  default     = true
}

variable "enable_s3_remediation" {
  description = "Habilitar remediación automática de S3 buckets"
  type        = bool
  default     = true
}

variable "enable_iam_remediation" {
  description = "Habilitar remediación automática de IAM"
  type        = bool
  default     = false
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
