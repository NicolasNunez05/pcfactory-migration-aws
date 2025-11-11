output "ec2_composite_alarm_arn" {
  description = "ARN de la alarma compuesta de EC2"
  value       = aws_cloudwatch_composite_alarm.ec2_health_critical.arn
}

output "rds_composite_alarm_arn" {
  description = "ARN de la alarma compuesta de RDS"
  value       = aws_cloudwatch_composite_alarm.rds_health_critical.arn
}

output "application_composite_alarm_arn" {
  description = "ARN de la alarma compuesta de aplicación completa"
  value       = aws_cloudwatch_composite_alarm.application_health.arn
}

output "infrastructure_composite_alarm_arn" {
  description = "ARN de la alarma compuesta de infraestructura"
  value       = length(aws_cloudwatch_composite_alarm.infrastructure_health) > 0 ? aws_cloudwatch_composite_alarm.infrastructure_health[0].arn : null
}

output "thresholds" {
  description = "Umbrales configurados para alarmas"
  value       = local.ec2_thresholds
}
