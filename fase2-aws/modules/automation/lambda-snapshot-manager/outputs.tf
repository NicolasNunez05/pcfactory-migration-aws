output "lambda_function_arn" {
  description = "ARN de la función Lambda"
  value       = aws_lambda_function.snapshot_manager.arn
}

output "lambda_function_name" {
  description = "Nombre de la función Lambda"
  value       = aws_lambda_function.snapshot_manager.function_name
}

output "eventbridge_rule_arn" {
  description = "ARN de la regla EventBridge"
  value       = aws_cloudwatch_event_rule.snapshot_schedule.arn
}

output "schedule_expression" {
  description = "Expresión de schedule configurada"
  value       = var.schedule_expression
}
