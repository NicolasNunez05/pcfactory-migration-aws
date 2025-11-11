variable "project_name" {
  description = "Nombre del proyecto"
  type        = string
}

variable "vpc_id" {
  description = "ID de la VPC"
  type        = string
}

variable "app_subnet_ids" {
  description = "IDs de las subredes privadas de aplicacion"
  type        = list(string)
}

variable "app_security_group_id" {
  description = "ID del Security Group de App"
  type        = string
}

variable "db_endpoint" {
  description = "Endpoint de la base de datos RDS"
  type        = string
}

variable "db_name" {
  description = "Nombre de la base de datos"
  type        = string
}

variable "db_username" {
  description = "Usuario de la base de datos"
  type        = string
}

variable "db_password" {
  description = "Contrasena de la base de datos"
  type        = string
  sensitive   = true
}

variable "target_group_arn" {
  description = "ARN del Target Group del ALB"
  type        = string
  default     = ""
}

# ============================================================================
# SNS TOPICS PARA ALARMAS
# ============================================================================
variable "sns_topic_critical_arn" {
  description = "ARN del SNS topic para alarmas críticas"
  type        = string
}

variable "sns_topic_warning_arn" {
  description = "ARN del SNS topic para alarmas de advertencia"
  type        = string
}

variable "environment" {
  description = "Ambiente de despliegue"
  type        = string
  default     = "dev"
}

variable "enable_xray" {
  description = "Habilitar AWS X-Ray tracing"
  type        = bool
  default     = false
}

variable "xray_policy_arn" {
  description = "ARN de la IAM policy de X-Ray"
  type        = string
  default     = ""
}

variable "kms_key_arn" {
  description = "ARN de la clave KMS para usar en permisos"
  type        = string
}
