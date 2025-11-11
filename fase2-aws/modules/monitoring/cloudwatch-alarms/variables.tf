variable "project_name" {
  description = "Nombre del proyecto"
  type        = string
}

variable "environment" {
  description = "Ambiente (dev, staging, prod)"
  type        = string
  default     = "dev"
}

# ----------------------------------------------------------------------------
# SNS Topics (se crearán en el siguiente paso)
# ----------------------------------------------------------------------------
variable "sns_topic_critical_arn" {
  description = "ARN del SNS topic para alarmas críticas"
  type        = string
}

variable "sns_topic_warning_arn" {
  description = "ARN del SNS topic para alarmas de advertencia"
  type        = string
  default     = ""
}

# ----------------------------------------------------------------------------
# Nombres de alarmas individuales (recibidos de otros módulos)
# ----------------------------------------------------------------------------
variable "ec2_alarm_names" {
  description = "Lista de nombres de alarmas de EC2"
  type        = list(string)
  default     = []
}

variable "rds_alarm_names" {
  description = "Lista de nombres de alarmas de RDS"
  type        = list(string)
  default     = []
}

variable "alb_alarm_names" {
  description = "Lista de nombres de alarmas de ALB"
  type        = list(string)
  default     = []
}

variable "vpn_alarm_names" {
  description = "Lista de nombres de alarmas de Client VPN"
  type        = list(string)
  default     = []
}

variable "firewall_alarm_names" {
  description = "Lista de nombres de alarmas de Network Firewall"
  type        = list(string)
  default     = []
}
