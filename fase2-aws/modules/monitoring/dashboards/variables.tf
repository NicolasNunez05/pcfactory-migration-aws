variable "project_name" {
  description = "Nombre del proyecto"
  type        = string
}

variable "environment" {
  description = "Ambiente (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "aws_region" {
  description = "Región de AWS"
  type        = string
  default     = "us-east-1"
}

# ============================================================================
# RECURSOS PARA DASHBOARDS
# ============================================================================

variable "asg_name" {
  description = "Nombre del Auto Scaling Group"
  type        = string
}

variable "db_instance_id" {
  description = "ID de la instancia RDS"
  type        = string
}

variable "alb_arn_suffix" {
  description = "ARN suffix del ALB (para métricas)"
  type        = string
  default     = ""  # Opcional si ALB está comentado
}

variable "target_group_arn_suffix" {
  description = "ARN suffix del Target Group"
  type        = string
  default     = ""  # Opcional si ALB está comentado
}

variable "vpn_endpoint_id" {
  description = "ID del Client VPN Endpoint"
  type        = string
}

variable "firewall_name" {
  description = "Nombre del Network Firewall"
  type        = string
}

variable "enable_alb_widgets" {
  description = "Habilitar widgets de ALB en dashboards (si ALB está desplegado)"
  type        = bool
  default     = false
}
