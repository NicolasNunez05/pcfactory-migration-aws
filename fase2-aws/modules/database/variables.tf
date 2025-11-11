variable "project_name" {
  description = "Nombre del proyecto"
  type        = string
}

variable "db_subnet_ids" {
  description = "IDs de las subredes privadas de DB"
  type        = list(string)
}

variable "db_security_group_id" {
  description = "ID del Security Group de DB"
  type        = string
}

variable "vpc_id" {
  description = "ID de la VPC"
  type        = string
}

variable "db_username" {
  description = "Usuario master de la base de datos"
  type        = string
  default     = "pcfactory"
}

variable "db_password" {
  description = "Contrasena master de la base de datos"
  type        = string
  sensitive   = true
}

variable "db_name" {
  description = "Nombre de la base de datos inicial"
  type        = string
  default     = "pcfactory"
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
