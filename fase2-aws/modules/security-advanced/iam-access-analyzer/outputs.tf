# =============================================================================
# OUTPUTS - IAM ACCESS ANALYZER
# =============================================================================

output "analyzer_arn" {
  description = "ARN del IAM Access Analyzer"
  value       = aws_accessanalyzer_analyzer.main.arn
}

output "analyzer_id" {
  description = "ID del IAM Access Analyzer"
  value       = aws_accessanalyzer_analyzer.main.id
}

output "analyzer_name" {
  description = "Nombre del analizador"
  value       = aws_accessanalyzer_analyzer.main.analyzer_name
}

output "analyzer_type" {
  description = "Tipo de analizador"
  value       = aws_accessanalyzer_analyzer.main.type
}

output "unused_access_enabled" {
  description = "Indica si el análisis de acceso no utilizado está habilitado"
  value       = var.enable_unused_access
}
