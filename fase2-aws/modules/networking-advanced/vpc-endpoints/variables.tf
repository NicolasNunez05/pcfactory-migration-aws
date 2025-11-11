# =============================================================================
# VARIABLES - VPC ENDPOINTS INTERFACE
# =============================================================================
# Endpoints privados para servicios AWS sin tráfico por Internet
# =============================================================================

variable "project_name" {
  description = "Nombre del proyecto"
  type        = string
}

variable "environment" {
  description = "Ambiente (dev, staging, prod)"
  type        = string
}

variable "vpc_id" {
  description = "ID de la VPC"
  type        = string
}

variable "private_subnet_ids" {
  description = "IDs de subnets privadas para endpoints"
  type        = list(string)
}

variable "security_group_ids" {
  description = "Security groups para endpoints"
  type        = list(string)
}

variable "enable_s3_gateway" {
  description = "Habilitar S3 Gateway Endpoint (sin costo)"
  type        = bool
  default     = true
}

variable "enable_dynamodb_gateway" {
  description = "Habilitar DynamoDB Gateway Endpoint (sin costo)"
  type        = bool
  default     = false
}

variable "enable_interface_endpoints" {
  description = "Endpoints interface a crear"
  type = object({
    rds              = bool
    elasticache      = bool
    secretsmanager   = bool
    kms              = bool
    ec2              = bool
    ec2messages      = bool
    ssm              = bool
    ssmmessages      = bool
    logs             = bool
    monitoring       = bool
    sts              = bool
    sns              = bool
    sqs              = bool
  })
  default = {
    rds            = true
    elasticache    = true
    secretsmanager = true
    kms            = true
    ec2            = true
    ec2messages    = true
    ssm            = true
    ssmmessages    = true
    logs           = true
    monitoring     = true
    sts            = true
    sns            = true
    sqs            = false
  }
}

variable "enable_private_dns" {
  description = "Habilitar DNS privado para endpoints interface"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags adicionales"
  type        = map(string)
  default     = {}
}
