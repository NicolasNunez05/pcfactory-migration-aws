variable "project_name" {
  type        = string
  description = "Nombre del proyecto"
}

variable "environment" {
  type        = string
  description = "Entorno (dev, prod)"
}

variable "alb_arn" {
  description = "ARN del Application Load Balancer"
  type        = string
  default     = null
}