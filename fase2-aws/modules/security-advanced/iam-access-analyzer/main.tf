# =============================================================================
# IAM ACCESS ANALYZER
# =============================================================================
# Análisis continuo de permisos y políticas IAM
# Proyecto: PCFactory Migration AWS - Capstone DuocUC 2025
# Autor: Nicolás Núñez Álvarez
# Última actualización: 09 de noviembre de 2025
# =============================================================================

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# =============================================================================
# IAM ACCESS ANALYZER
# =============================================================================

resource "aws_accessanalyzer_analyzer" "main" {
  analyzer_name = var.analyzer_name != null ? var.analyzer_name : "${var.project_name}-${var.environment}-analyzer"
  type          = var.analyzer_type
  

  tags = merge(
    {
      Name        = "${var.project_name}-${var.environment}-access-analyzer"
      Environment = var.environment
      Project     = var.project_name
      ManagedBy   = "Terraform"
    },
    var.tags
  )
}

# =============================================================================
# ARCHIVE RULES (filtrar hallazgos esperados)
# =============================================================================

# Regla: Ignorar acceso público a S3 buckets de logs
resource "aws_accessanalyzer_archive_rule" "s3_logs_public" {
  analyzer_name = aws_accessanalyzer_analyzer.main.analyzer_name
  rule_name     = "archive-s3-logs-public-access"

  filter {
    criteria = "resourceType"
    eq       = ["AWS::S3::Bucket"]
  }

  filter {
    criteria = "resource"
    contains = ["-logs-"]
  }
}

# resource "aws_accessanalyzer_archive_rule" "cloudwatch_aws_services" {
#   analyzer_name = aws_accessanalyzer_analyzer.main.analyzer_name
#   rule_name     = "archive-cloudwatch-aws-services"
#
#   filter {
#     criteria = "principal.AWS"
#     exists   = true
#   }
# }