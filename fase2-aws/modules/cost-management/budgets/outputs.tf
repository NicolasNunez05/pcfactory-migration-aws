# =============================================================================
# OUTPUTS - MÓDULO AWS BUDGETS
# =============================================================================

# -----------------------------------------------------------------------------
# SNS TOPIC
# -----------------------------------------------------------------------------

output "sns_topic_arn" {
  description = "ARN del SNS topic para notificaciones de budget"
  value       = local.sns_topic_arn
}

output "sns_topic_name" {
  description = "Nombre del SNS topic creado"
  value       = length(aws_sns_topic.budget_alerts) > 0 ? aws_sns_topic.budget_alerts[0].name : null
}

# -----------------------------------------------------------------------------
# PRESUPUESTOS
# -----------------------------------------------------------------------------

output "global_budget_name" {
  description = "Nombre del presupuesto global"
  value       = aws_budgets_budget.global.name
}

output "global_budget_amount" {
  description = "Monto del presupuesto global"
  value       = var.global_monthly_budget
}

output "ec2_budget_name" {
  description = "Nombre del presupuesto EC2"
  value       = var.enable_service_budgets ? aws_budgets_budget.ec2[0].name : null
}

output "rds_budget_name" {
  description = "Nombre del presupuesto RDS"
  value       = var.enable_service_budgets ? aws_budgets_budget.rds[0].name : null
}

output "s3_budget_name" {
  description = "Nombre del presupuesto S3"
  value       = var.enable_service_budgets ? aws_budgets_budget.s3[0].name : null
}

output "elasticache_budget_name" {
  description = "Nombre del presupuesto ElastiCache"
  value       = var.enable_service_budgets ? aws_budgets_budget.elasticache[0].name : null
}

# -----------------------------------------------------------------------------
# RESUMEN
# -----------------------------------------------------------------------------

output "total_monthly_budget" {
  description = "Presupuesto mensual total configurado"
  value = var.enable_service_budgets ? (
    var.ec2_monthly_budget +
    var.rds_monthly_budget +
    var.s3_monthly_budget +
    var.elasticache_monthly_budget +
    var.other_services_budget
  ) : var.global_monthly_budget
}

output "alert_threshold" {
  description = "Porcentaje de alerta configurado"
  value       = var.alert_threshold_percentage
}

output "notification_emails" {
  description = "Emails configurados para recibir alertas"
  value       = var.notification_emails
  sensitive   = true
}
