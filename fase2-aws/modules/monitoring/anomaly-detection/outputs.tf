# =============================================================================
# OUTPUTS - ANOMALY DETECTION
# =============================================================================

output "cpu_anomaly_alarm_arn" {
  description = "ARN de la alarma de anomalía de CPU"
  value       = var.enable_cpu_anomaly ? aws_cloudwatch_metric_alarm.cpu_anomaly[0].arn : null
}

output "db_anomaly_alarm_arn" {
  description = "ARN de la alarma de anomalía de DB"
  value       = var.enable_db_anomaly ? aws_cloudwatch_metric_alarm.db_connections_anomaly[0].arn : null
}

output "network_anomaly_alarm_arn" {
  description = "ARN de la alarma de anomalía de red"
  value       = var.enable_network_anomaly ? aws_cloudwatch_metric_alarm.network_in_anomaly[0].arn : null
}

output "request_anomaly_alarm_arn" {
  description = "ARN de la alarma de anomalía de requests"
  value       = var.enable_request_anomaly ? aws_cloudwatch_metric_alarm.request_count_anomaly[0].arn : null
}

output "redis_anomaly_alarm_arn" {
  description = "ARN de la alarma de anomalía de Redis"
  value       = aws_cloudwatch_metric_alarm.redis_cpu_anomaly.arn
}

output "enabled_detectors" {
  description = "Lista de detectores habilitados"
  value = compact([
    var.enable_cpu_anomaly ? "CPU" : "",
    var.enable_db_anomaly ? "Database" : "",
    var.enable_network_anomaly ? "Network" : "",
    var.enable_request_anomaly ? "Requests" : "",
    "Redis"
  ])
}
