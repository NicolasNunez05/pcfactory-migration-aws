output "lambda_function_arn" {
  description = "ARN de la función Lambda"
  value       = aws_lambda_function.alarm_responder.arn
}

output "lambda_function_name" {
  description = "Nombre de la función Lambda"
  value       = aws_lambda_function.alarm_responder.function_name
}
