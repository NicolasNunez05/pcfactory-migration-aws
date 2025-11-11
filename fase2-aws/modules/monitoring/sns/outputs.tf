output "critical_topic_arn" {
  description = "ARN del SNS topic para alarmas críticas"
  value       = aws_sns_topic.critical.arn
}

output "critical_topic_name" {
  description = "Nombre del SNS topic crítico"
  value       = aws_sns_topic.critical.name
}

output "warning_topic_arn" {
  description = "ARN del SNS topic para alarmas de advertencia"
  value       = aws_sns_topic.warning.arn
}

output "warning_topic_name" {
  description = "Nombre del SNS topic de advertencia"
  value       = aws_sns_topic.warning.name
}

output "info_topic_arn" {
  description = "ARN del SNS topic para notificaciones informativas"
  value       = aws_sns_topic.info.arn
}

output "info_topic_name" {
  description = "Nombre del SNS topic informativo"
  value       = aws_sns_topic.info.name
}
