output "xray_sampling_rule_id" {
  description = "ID de la regla de sampling por defecto"
  value       = aws_xray_sampling_rule.default.id
}

output "xray_group_errors_arn" {
  description = "ARN del grupo X-Ray de errores"
  value       = aws_xray_group.app_errors.arn
}

output "xray_group_slow_arn" {
  description = "ARN del grupo X-Ray de requests lentos"
  value       = aws_xray_group.slow_requests.arn
}

output "xray_policy_arn" {
  description = "ARN de la IAM policy para X-Ray"
  value       = aws_iam_policy.xray.arn
}
