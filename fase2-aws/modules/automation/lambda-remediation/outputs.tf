# =============================================================================
# OUTPUTS - LAMBDA REMEDIATION
# =============================================================================

output "sg_remediation_lambda_arn" {
  description = "ARN de Lambda para remediación de Security Groups"
  value       = var.enable_sg_remediation ? aws_lambda_function.sg_remediation[0].arn : null
}

output "s3_remediation_lambda_arn" {
  description = "ARN de Lambda para remediación de S3"
  value       = var.enable_s3_remediation ? aws_lambda_function.s3_remediation[0].arn : null
}

output "remediation_role_arn" {
  description = "ARN del rol IAM de remediación"
  value       = aws_iam_role.lambda_remediation.arn
}

output "enabled_remediations" {
  description = "Lista de remediaciones habilitadas"
  value = compact([
    var.enable_sg_remediation ? "Security Groups" : "",
    var.enable_s3_remediation ? "S3 Buckets" : "",
    var.enable_iam_remediation ? "IAM" : ""
  ])
}
