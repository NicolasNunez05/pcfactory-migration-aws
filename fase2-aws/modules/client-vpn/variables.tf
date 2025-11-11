variable "project_name" {
  description = "Nombre del proyecto"
  type        = string
}

variable "vpc_id" {
  description = "ID de la VPC"
  type        = string
}

variable "vpn_subnet_ids" {
  description = "IDs de las subnets para asociar VPN"
  type        = list(string)
}

variable "server_certificate_arn" {
  description = "ARN del certificado del servidor en ACM"
  type        = string
}

variable "client_root_certificate_arn" {
  description = "ARN del certificado raíz del cliente en ACM"
  type        = string
}

variable "vpn_cidr" {
  description = "CIDR pool para clientes VPN"
  type        = string
  default     = "172.16.0.0/22"
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
