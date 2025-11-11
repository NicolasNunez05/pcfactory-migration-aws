variable "project_name" {
  description = "Nombre del proyecto"
  type        = string
}

variable "vpc_id" {
  description = "ID de la VPC"
  type        = string
}

variable "public_subnets" {
  description = "IDs de las subredes publicas"
  type        = list(string)
}

variable "alb_sg_id" {
  description = "ID del Security Group del ALB"
  type        = string
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
