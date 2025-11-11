# =============================================================================
# MÓDULO ELASTICACHE REDIS - CONFIGURACIÓN PROFESIONAL
# =============================================================================
# Cluster Redis con Cluster Mode Enabled, Multi-AZ y alta disponibilidad
# =============================================================================

# Data sources
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

# =============================================================================
# SUBNET GROUP
# =============================================================================

resource "aws_elasticache_subnet_group" "redis" {
  name        = "${var.project_name}-${var.environment}-redis-subnet-group"
  description = "Subnet group para ElastiCache Redis - ${var.project_name}"
  subnet_ids  = var.private_subnet_ids

  tags = merge(
    {
      Name        = "${var.project_name}-${var.environment}-redis-subnet-group"
      Environment = var.environment
      Project     = var.project_name
      ManagedBy   = "Terraform"
    },
    var.tags
  )
}

# =============================================================================
# SECURITY GROUP
# =============================================================================

resource "aws_security_group" "redis" {
  name        = "${var.project_name}-${var.environment}-redis-sg"
  description = "Security group para ElastiCache Redis"
  vpc_id      = var.vpc_id

  tags = merge(
    {
      Name        = "${var.project_name}-${var.environment}-redis-sg"
      Environment = var.environment
      Project     = var.project_name
      ManagedBy   = "Terraform"
    },
    var.tags
  )
}

# Ingress rule - Permitir acceso desde security groups especificados
resource "aws_security_group_rule" "redis_ingress_from_sg" {
  count = length(var.allowed_security_group_ids) > 0 ? length(var.allowed_security_group_ids) : 0

  type                     = "ingress"
  from_port                = var.port
  to_port                  = var.port
  protocol                 = "tcp"
  source_security_group_id = var.allowed_security_group_ids[count.index]
  security_group_id        = aws_security_group.redis.id
  description              = "Allow Redis access from application security group"
}

# Ingress rule - Permitir acceso desde bloques CIDR
resource "aws_security_group_rule" "redis_ingress_from_cidr" {
  count = length(var.allowed_cidr_blocks) > 0 ? 1 : 0

  type             = "ingress"
  from_port        = var.port
  to_port          = var.port
  protocol         = "tcp"
  cidr_blocks      = var.allowed_cidr_blocks
  security_group_id = aws_security_group.redis.id
  description      = "Allow Redis access from specified CIDR blocks"
}

# Egress rule - Permitir todo el tráfico saliente
resource "aws_security_group_rule" "redis_egress" {
  type             = "egress"
  from_port        = 0
  to_port          = 0
  protocol         = "-1"
  cidr_blocks      = ["0.0.0.0/0"]
  security_group_id = aws_security_group.redis.id
  description      = "Allow all outbound traffic"
}

# =============================================================================
# PARAMETER GROUP
# =============================================================================

resource "aws_elasticache_parameter_group" "redis" {
  name        = "${var.project_name}-${var.environment}-redis-params"
  family      = var.parameter_group_family
  description = "Parameter group para ElastiCache Redis - ${var.project_name}"

  # Configuración de parámetros optimizados
  parameter {
    name  = "maxmemory-policy"
    value = "allkeys-lru"
  }

  parameter {
    name  = "timeout"
    value = "300"
  }

  parameter {
    name  = "tcp-keepalive"
    value = "300"
  }

  tags = merge(
    {
      Name        = "${var.project_name}-${var.environment}-redis-params"
      Environment = var.environment
      Project     = var.project_name
      ManagedBy   = "Terraform"
    },
    var.tags
  )
}

# =============================================================================
# REPLICATION GROUP (Cluster Mode con un solo node group)
# =============================================================================

resource "aws_elasticache_replication_group" "redis" {
  replication_group_id = "${var.project_name}-${var.environment}-redis"
  description          = "ElastiCache Redis Cluster para ${var.project_name} - ${var.environment}"

  engine               = "redis"
  engine_version       = var.redis_version
  node_type            = var.node_type
  port                 = var.port
  parameter_group_name = aws_elasticache_parameter_group.redis.name

  num_node_groups         = 1                      # Cambiado para usar solo un node group
  replicas_per_node_group = var.replicas_per_node_group

  subnet_group_name  = aws_elasticache_subnet_group.redis.name
  security_group_ids = [aws_security_group.redis.id]

  multi_az_enabled           = var.multi_az_enabled
  automatic_failover_enabled = var.automatic_failover_enabled

  transit_encryption_enabled = var.transit_encryption_enabled
  at_rest_encryption_enabled = var.at_rest_encryption_enabled
  kms_key_id                 = var.at_rest_encryption_enabled ? var.kms_key_id : null
  auth_token                 = var.auth_token_enabled ? var.auth_token : null

  snapshot_retention_limit   = var.snapshot_retention_limit
  snapshot_window           = var.snapshot_window
  final_snapshot_identifier = var.final_snapshot_identifier != null ? var.final_snapshot_identifier : "${var.project_name}-${var.environment}-redis-final-snapshot"

  maintenance_window           = var.maintenance_window
  auto_minor_version_upgrade = var.auto_minor_version_upgrade

  notification_topic_arn = var.notification_topic_arn

  dynamic "log_delivery_configuration" {
    for_each = var.log_delivery_configuration
    content {
      destination      = log_delivery_configuration.value.destination
      destination_type = log_delivery_configuration.value.destination_type
      log_format       = log_delivery_configuration.value.log_format
      log_type         = log_delivery_configuration.value.log_type
    }
  }

  tags = merge(
    {
      Name        = "${var.project_name}-${var.environment}-redis"
      Environment = var.environment
      Project     = var.project_name
      ManagedBy   = "Terraform"
      ClusterMode = "Enabled"
      MultiAZ     = tostring(var.multi_az_enabled)
      Version     = var.redis_version
    },
    var.tags
  )

  lifecycle {
    prevent_destroy = false
  }
}
