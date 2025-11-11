output "lambda_function_arn" {
  description = "ARN de la función Lambda"
  value       = aws_lambda_function.log_parser.arn
}

output "lambda_function_name" {
  description = "Nombre de la función Lambda"
  value       = aws_lambda_function.log_parser.function_name
}

output "lambda_role_arn" {
  description = "ARN del IAM role de Lambda"
  value       = aws_iam_role.lambda_log_parser.arn
}
