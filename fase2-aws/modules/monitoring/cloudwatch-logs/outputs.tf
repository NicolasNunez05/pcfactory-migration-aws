output "centralized_app_log_group_name" {
  description = "Nombre del log group centralizado de aplicación"
  value       = aws_cloudwatch_log_group.centralized_app.name
}

output "centralized_app_log_group_arn" {
  description = "ARN del log group centralizado de aplicación"
  value       = aws_cloudwatch_log_group.centralized_app.arn
}

output "centralized_infra_log_group_name" {
  description = "Nombre del log group centralizado de infraestructura"
  value       = aws_cloudwatch_log_group.centralized_infra.name
}

output "centralized_security_log_group_name" {
  description = "Nombre del log group centralizado de seguridad"
  value       = aws_cloudwatch_log_group.centralized_security.name
}

output "kms_key_id" {
  description = "ID de la KMS key para logs (si está habilitada)"
  value       = var.enable_encryption ? aws_kms_key.logs[0].id : null
}

output "kms_key_arn" {
  description = "ARN de la KMS key para logs"
  value       = var.enable_encryption ? aws_kms_key.logs[0].arn : null
}
