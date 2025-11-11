# =============================================================================
# OUTPUTS - SECURITY HUB
# =============================================================================

output "security_hub_id" {
  description = "ID de Security Hub"
  value       = aws_securityhub_account.main.id
}

output "security_hub_arn" {
  description = "ARN de Security Hub"
  value       = aws_securityhub_account.main.arn
}

output "enabled_standards" {
  description = "Lista de estándares habilitados"
  value = compact([
    var.enable_aws_foundational_security ? "AWS Foundational Security Best Practices" : "",
    var.enable_cis_aws_foundations_v1_4 ? "CIS AWS Foundations v1.4" : "",
    var.enable_pci_dss ? "PCI DSS v3.2.1" : "",
    var.enable_nist ? "NIST 800-53 Rev 5" : ""
  ])
}

output "control_finding_generator" {
  description = "Tipo de generador de hallazgos"
  value       = var.control_finding_generator
}

output "eventbridge_rule_arn" {
  description = "ARN de la regla EventBridge"
  value       = aws_cloudwatch_event_rule.security_hub_findings.arn
}
