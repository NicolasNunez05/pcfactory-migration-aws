variable "project_name" {
  description = "Nombre del proyecto"
  type        = string
  default     = "pcfactory-migration"
}

variable "vpc_cidr" {
  description = "CIDR block para la VPC"
  type        = string
  default     = "10.20.0.0/16"
}

variable "availability_zones" {
  description = "Zonas de disponibilidad"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
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


variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment"
  type        = string
  default     = "dev"
}
