# =============================================================================
# OUTPUTS - MÓDULO S3 STORAGE
# =============================================================================

# -----------------------------------------------------------------------------
# BACKUPS BUCKET
# -----------------------------------------------------------------------------

output "backups_bucket_id" {
  description = "ID del bucket de backups"
  value       = var.enable_backups_bucket ? aws_s3_bucket.backups[0].id : null
}

output "backups_bucket_arn" {
  description = "ARN del bucket de backups"
  value       = var.enable_backups_bucket ? aws_s3_bucket.backups[0].arn : null
}

output "backups_bucket_domain_name" {
  description = "Domain name del bucket de backups"
  value       = var.enable_backups_bucket ? aws_s3_bucket.backups[0].bucket_domain_name : null
}

output "backups_bucket_region" {
  description = "Región del bucket de backups"
  value       = var.enable_backups_bucket ? aws_s3_bucket.backups[0].region : null
}

# -----------------------------------------------------------------------------
# LOGS BUCKET
# -----------------------------------------------------------------------------

output "logs_bucket_id" {
  description = "ID del bucket de logs"
  value       = var.enable_logs_bucket ? aws_s3_bucket.logs[0].id : null
}

output "logs_bucket_arn" {
  description = "ARN del bucket de logs"
  value       = var.enable_logs_bucket ? aws_s3_bucket.logs[0].arn : null
}

output "logs_bucket_domain_name" {
  description = "Domain name del bucket de logs"
  value       = var.enable_logs_bucket ? aws_s3_bucket.logs[0].bucket_domain_name : null
}

# -----------------------------------------------------------------------------
# ARTIFACTS BUCKET
# -----------------------------------------------------------------------------

output "artifacts_bucket_id" {
  description = "ID del bucket de artifacts"
  value       = var.enable_artifacts_bucket ? aws_s3_bucket.artifacts[0].id : null
}

output "artifacts_bucket_arn" {
  description = "ARN del bucket de artifacts"
  value       = var.enable_artifacts_bucket ? aws_s3_bucket.artifacts[0].arn : null
}

output "artifacts_bucket_domain_name" {
  description = "Domain name del bucket de artifacts"
  value       = var.enable_artifacts_bucket ? aws_s3_bucket.artifacts[0].bucket_domain_name : null
}

# -----------------------------------------------------------------------------
# INFORMACIÓN GENERAL
# -----------------------------------------------------------------------------

output "all_bucket_arns" {
  description = "Lista de todos los ARNs de buckets creados"
  value = compact([
    var.enable_backups_bucket ? aws_s3_bucket.backups[0].arn : "",
    var.enable_logs_bucket ? aws_s3_bucket.logs[0].arn : "",
    var.enable_artifacts_bucket ? aws_s3_bucket.artifacts[0].arn : ""
  ])
}

output "kms_key_id" {
  description = "ID de la clave KMS usada para cifrado"
  value       = var.kms_key_id
}

output "logs_bucket_name" {
  value       = aws_s3_bucket.logs[0].bucket
  description = "Nombre del bucket de logs"
}
