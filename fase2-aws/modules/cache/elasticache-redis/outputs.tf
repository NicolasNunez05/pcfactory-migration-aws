# =============================================================================
# OUTPUTS - MÓDULO ELASTICACHE REDIS
# =============================================================================

# -----------------------------------------------------------------------------
# REPLICATION GROUP
# -----------------------------------------------------------------------------

output "replication_group_id" {
  description = "ID del replication group de Redis"
  value       = aws_elasticache_replication_group.redis.id
}

output "replication_group_arn" {
  description = "ARN del replication group de Redis"
  value       = aws_elasticache_replication_group.redis.arn
}

output "configuration_endpoint_address" {
  description = "Configuration endpoint address para Cluster Mode Enabled"
  value       = aws_elasticache_replication_group.redis.configuration_endpoint_address
}

output "primary_endpoint_address" {
  description = "Primary endpoint address"
  value       = try(aws_elasticache_replication_group.redis.primary_endpoint_address, null)
}

output "reader_endpoint_address" {
  description = "Reader endpoint address"
  value       = try(aws_elasticache_replication_group.redis.reader_endpoint_address, null)
}

output "port" {
  description = "Puerto de Redis"
  value       = aws_elasticache_replication_group.redis.port
}

# -----------------------------------------------------------------------------
# SECURITY GROUP
# -----------------------------------------------------------------------------

output "security_group_id" {
  description = "ID del security group de Redis"
  value       = aws_security_group.redis.id
}

output "security_group_arn" {
  description = "ARN del security group de Redis"
  value       = aws_security_group.redis.arn
}

# -----------------------------------------------------------------------------
# SUBNET GROUP
# -----------------------------------------------------------------------------

output "subnet_group_name" {
  description = "Nombre del subnet group"
  value       = aws_elasticache_subnet_group.redis.name
}

# -----------------------------------------------------------------------------
# PARAMETER GROUP
# -----------------------------------------------------------------------------

output "parameter_group_name" {
  description = "Nombre del parameter group"
  value       = aws_elasticache_parameter_group.redis.name
}

# -----------------------------------------------------------------------------
# INFORMACIÓN DEL CLUSTER
# -----------------------------------------------------------------------------

output "cluster_enabled" {
  description = "Indica si Cluster Mode está habilitado"
  value       = var.num_node_groups > 1
}

output "num_shards" {
  description = "Número de shards en el cluster"
  value       = var.num_node_groups
}

output "replicas_per_shard" {
  description = "Número de réplicas por shard"
  value       = var.replicas_per_node_group
}

output "total_nodes" {
  description = "Número total de nodos en el cluster"
  value       = var.num_node_groups * (var.replicas_per_node_group + 1)
}

output "engine_version" {
  description = "Versión de Redis"
  value       = aws_elasticache_replication_group.redis.engine_version_actual
}
