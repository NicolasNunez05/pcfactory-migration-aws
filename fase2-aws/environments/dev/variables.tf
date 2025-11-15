variable "project_name" {
  description = "Nombre del proyecto"
  type        = string
  default     = "pcfactory-migration"
}

variable "aws_region" {
  description = "Región AWS"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Entorno (dev, staging, prod)"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment debe ser: dev, staging, o prod."
  }
}

# VPC - AHORA EXTRAÍDA AUTOMÁTICAMENTE
variable "vpc_cidr" {
  description = "CIDR de la VPC"
  type        = string
  default     = "10.20.0.0/16"
}
variable "rds_master_password" {
  description = "Password maestro de RDS para Secrets Manager"
  type        = string
  sensitive   = true
  default     = "PCFactory2024!ChangeMe"
}

variable "kms_key_id" {
  description = "ARN de la clave KMS para cifrado en S3"
  type        = string
}


variable "availability_zones" {
  description = "Zonas de disponibilidad"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}


variable "max_size" {
  type = number
  default = 5
}

variable "db_username" {
  type = string
  default = "admin"
}