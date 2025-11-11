# =============================================================================
# VARIABLES - AWS SECURITY HUB
# =============================================================================
# Dashboard consolidado de seguridad y compliance
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

variable "enable_default_standards" {
  description = "Habilitar estándares de seguridad por defecto"
  type        = bool
  default     = true
}

variable "enable_aws_foundational_security" {
  description = "Habilitar AWS Foundational Security Best Practices"
  type        = bool
  default     = true
}

variable "enable_cis_aws_foundations_v1_4" {
  description = "Habilitar CIS AWS Foundations Benchmark v1.4"
  type        = bool
  default     = true
}

variable "enable_pci_dss" {
  description = "Habilitar PCI DSS"
  type        = bool
  default     = false
}

variable "enable_nist" {
  description = "Habilitar NIST 800-53"
  type        = bool
  default     = false
}

variable "control_finding_generator" {
  description = "Generador de hallazgos de controles: SECURITY_CONTROL o STANDARD_CONTROL"
  type        = string
  default     = "SECURITY_CONTROL"
}

variable "auto_enable_controls" {
  description = "Habilitar controles automáticamente para nuevos estándares"
  type        = bool
  default     = true
}

variable "sns_topic_arn" {
  description = "ARN del SNS topic para notificaciones"
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags adicionales"
  type        = map(string)
  default     = {}
}



variable "enable_cis_aws_v1_4" {
  description = "Habilitar el estándar CIS AWS Foundations Benchmark v1.4.0"
  type        = bool
  default     = true
}
