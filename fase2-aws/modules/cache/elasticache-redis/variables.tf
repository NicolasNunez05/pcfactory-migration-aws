# =============================================================================
# VARIABLES - MÓDULO ELASTICACHE REDIS
# =============================================================================
# Configuración de ElastiCache Redis con Cluster Mode Enabled
# Proyecto: PCFactory Migration AWS - Capstone DuocUC 2025
# =============================================================================

variable "project_name" {
  description = "Nombre del proyecto"
  type        = string
}

variable "environment" {
  description = "Ambiente (dev, staging, prod)"
  type        = string
}

# -----------------------------------------------------------------------------
# CONFIGURACIÓN DE RED
# -----------------------------------------------------------------------------

variable "vpc_id" {
  description = "ID de la VPC"
  type        = string
}

variable "private_subnet_ids" {
  description = "Lista de IDs de subnets privadas para ElastiCache"
  type        = list(string)
}

variable "allowed_security_group_ids" {
  description = "Lista de security groups que pueden acceder a Redis"
  type        = list(string)
  default     = []
}

variable "allowed_cidr_blocks" {
  description = "Lista de bloques CIDR que pueden acceder a Redis"
  type        = list(string)
  default     = []
}

# -----------------------------------------------------------------------------
# CONFIGURACIÓN DEL CLUSTER
# -----------------------------------------------------------------------------

variable "node_type" {
  description = "Tipo de instancia para nodos Redis"
  type        = string
  default     = "cache.t4g.micro"
}

variable "num_node_groups" {
  description = "Número de shards (node groups) en el cluster"
  type        = number
  default     = 3
}

variable "replicas_per_node_group" {
  description = "Número de réplicas por shard"
  type        = number
  default     = 2
}

variable "redis_version" {
  description = "Versión de Redis"
  type        = string
  default     = "7.1"
}

variable "port" {
  description = "Puerto de Redis"
  type        = number
  default     = 6379
}

variable "parameter_group_family" {
  description = "Familia del parameter group"
  type        = string
  default     = "redis7"
}

# -----------------------------------------------------------------------------
# ALTA DISPONIBILIDAD
# -----------------------------------------------------------------------------

variable "multi_az_enabled" {
  description = "Habilitar Multi-AZ con failover automático"
  type        = bool
  default     = true
}

variable "automatic_failover_enabled" {
  description = "Habilitar failover automático"
  type        = bool
  default     = true
}

# -----------------------------------------------------------------------------
# SEGURIDAD
# -----------------------------------------------------------------------------

variable "transit_encryption_enabled" {
  description = "Habilitar cifrado en tránsito (TLS)"
  type        = bool
  default     = true
}

variable "at_rest_encryption_enabled" {
  description = "Habilitar cifrado en reposo"
  type        = bool
  default     = true
}

variable "kms_key_id" {
  description = "ARN de la clave KMS para cifrado en reposo"
  type        = string
  default     = null
}

variable "auth_token_enabled" {
  description = "Habilitar autenticación con token"
  type        = bool
  default     = true
}

variable "auth_token" {
  description = "Token de autenticación para Redis (mínimo 16 caracteres)"
  type        = string
  sensitive   = true
  default     = null
}

# -----------------------------------------------------------------------------
# BACKUPS
# -----------------------------------------------------------------------------

variable "snapshot_retention_limit" {
  description = "Número de días para retener snapshots automáticos"
  type        = number
  default     = 7
}

variable "snapshot_window" {
  description = "Ventana de tiempo para snapshots (formato: HH:MM-HH:MM UTC)"
  type        = string
  default     = "03:00-05:00"
}

variable "final_snapshot_identifier" {
  description = "Nombre del snapshot final al eliminar el cluster"
  type        = string
  default     = null
}

# -----------------------------------------------------------------------------
# MANTENIMIENTO
# -----------------------------------------------------------------------------

variable "maintenance_window" {
  description = "Ventana de mantenimiento (formato: ddd:HH:MM-ddd:HH:MM UTC)"
  type        = string
  default     = "sun:02:00-sun:04:00"
}

variable "auto_minor_version_upgrade" {
  description = "Habilitar actualizaciones automáticas de versión menor"
  type        = bool
  default     = true
}

# -----------------------------------------------------------------------------
# NOTIFICACIONES
# -----------------------------------------------------------------------------

variable "notification_topic_arn" {
  description = "ARN del SNS topic para notificaciones de ElastiCache"
  type        = string
  default     = null
}

# -----------------------------------------------------------------------------
# LOGS
# -----------------------------------------------------------------------------

variable "log_delivery_configuration" {
  description = "Configuración de entrega de logs a CloudWatch"
  type = list(object({
    destination      = string
    destination_type = string
    log_format       = string
    log_type         = string
  }))
  default = []
}

# -----------------------------------------------------------------------------
# TAGS
# -----------------------------------------------------------------------------

variable "tags" {
  description = "Tags adicionales para recursos"
  type        = map(string)
  default     = {}
}
