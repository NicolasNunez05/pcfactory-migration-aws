output "db_endpoint" {
  description = "Endpoint de conexion a RDS"
  value       = aws_db_instance.postgresql.address
}

output "db_port" {
  description = "Puerto de conexion a RDS"
  value       = aws_db_instance.postgresql.port
}

output "db_name" {
  description = "Nombre de la base de datos"
  value       = aws_db_instance.postgresql.db_name
}

output "db_dns_name" {
  description = "Nombre DNS privado de la base de datos"
  value       = "db.corp.local"
}

output "private_zone_id" {
  description = "ID de la zona privada de Route 53"
  value       = aws_route53_zone.private.zone_id
}

output "db_instance_id" {
  description = "ID de la instancia RDS"
  value       = aws_db_instance.postgresql.id
}


# ============================================================================
# OUTPUTS - CLOUDWATCH LOGS
# ============================================================================

#output "rds_postgresql_log_group_name" {
 # description = "Nombre del log group de PostgreSQL"
 # value       = aws_cloudwatch_log_group.rds_postgresql.name
#}

#output "rds_postgresql_log_group_arn" {
 # description = "ARN del log group de PostgreSQL"
  #value       = aws_cloudwatch_log_group.rds_postgresql.arn
#}

output "rds_upgrade_log_group_name" {
  description = "Nombre del log group de upgrades RDS"
  value       = aws_cloudwatch_log_group.rds_upgrade.name
}
