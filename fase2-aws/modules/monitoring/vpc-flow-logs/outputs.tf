output "vpc_flow_log_id" {
  description = "ID del VPC Flow Log principal"
  value       = aws_flow_log.vpc_main.id
}

output "vpc_flow_log_group_name" {
  description = "Nombre del log group de VPC Flow Logs"
  value       = aws_cloudwatch_log_group.vpc_flow_logs.name
}

output "vpc_flow_log_group_arn" {
  description = "ARN del log group de VPC Flow Logs"
  value       = aws_cloudwatch_log_group.vpc_flow_logs.arn
}

output "subnet_flow_log_ids" {
  description = "IDs de Flow Logs de subnets"
  value       = { for k, v in aws_flow_log.subnets_public : k => v.id }
}

output "rejected_connections_alarm_arn" {
  description = "ARN de la alarma de conexiones rechazadas"
  value       = aws_cloudwatch_metric_alarm.rejected_connections_high.arn
}

output "ssh_attempts_alarm_arn" {
  description = "ARN de la alarma de intentos SSH"
  value       = aws_cloudwatch_metric_alarm.ssh_attempts_high.arn
}
