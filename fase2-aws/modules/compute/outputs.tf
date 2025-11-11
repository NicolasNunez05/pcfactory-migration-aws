

output "launch_template_id" {
  description = "ID del Launch Template"
  value       = aws_launch_template.app.id
}

# ============================================================================
# OUTPUTS - CLOUDWATCH LOGS
# ============================================================================

output "app_log_group_name" {
  description = "Nombre del log group de aplicación"
  value       = aws_cloudwatch_log_group.app_logs.name
}

output "app_log_group_arn" {
  description = "ARN del log group de aplicación"
  value       = aws_cloudwatch_log_group.app_logs.arn
}

output "system_log_group_name" {
  description = "Nombre del log group del sistema"
  value       = aws_cloudwatch_log_group.system_logs.name
}

output "system_log_group_arn" {
  description = "ARN del log group del sistema"
  value       = aws_cloudwatch_log_group.system_logs.arn
}



output "autoscaling_group_name" {
  description = "Nombre del Auto Scaling Group"
  value       = aws_autoscaling_group.app.name
}