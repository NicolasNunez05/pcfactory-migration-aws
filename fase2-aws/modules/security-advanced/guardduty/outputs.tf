# =============================================================================
# OUTPUTS - GUARDDUTY
# =============================================================================

output "detector_id" {
  description = "ID del GuardDuty detector"
  value       = aws_guardduty_detector.main.id
}

output "detector_arn" {
  description = "ARN del GuardDuty detector"
  value       = aws_guardduty_detector.main.arn
}

output "s3_protection_enabled" {
  description = "Indica si la protección S3 está habilitada"
  value       = var.enable_s3_protection
}

output "malware_protection_enabled" {
  description = "Indica si la protección contra malware está habilitada"
  value       = var.enable_malware_protection
}

output "finding_publishing_frequency" {
  description = "Frecuencia de publicación de hallazgos"
  value       = var.finding_publishing_frequency
}

output "eventbridge_rule_arn" {
  description = "ARN de la regla EventBridge para hallazgos"
  value       = aws_cloudwatch_event_rule.guardduty_findings.arn
}
