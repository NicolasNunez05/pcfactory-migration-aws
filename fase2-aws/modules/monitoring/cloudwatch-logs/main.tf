# ============================================================================
# CLOUDWATCH LOGS - AGREGACIÓN CENTRALIZADA
# ============================================================================
# Este módulo implementa el componente CENTRAL del modelo híbrido
# - Log Groups centrales con retención larga (compliance)
# - Subscriptions para agregar logs de otros módulos
# - Insights queries predefinidas para análisis
# - Exportación a S3 para archivado de largo plazo


# ----------------------------------------------------------------------------
# LOG GROUP CENTRALIZADO - Todos los logs de aplicación
# ----------------------------------------------------------------------------
resource "aws_cloudwatch_log_group" "centralized_app" {
  name              = "/aws/centralized/${var.project_name}/application"
  retention_in_days = var.retention_days_centralized  # 90 días para compliance
  kms_key_id        = var.enable_encryption ? aws_kms_key.logs[0].arn : null

  tags = {
    Name        = "${var.project_name}-centralized-app-logs"
    Environment = var.environment
    Type        = "Centralized"
    Compliance  = "true"
  }
}

# ----------------------------------------------------------------------------
# LOG GROUP CENTRALIZADO - Logs de infraestructura
# ----------------------------------------------------------------------------
resource "aws_cloudwatch_log_group" "centralized_infra" {
  name              = "/aws/centralized/${var.project_name}/infrastructure"
  retention_in_days = var.retention_days_centralized
  kms_key_id        = var.enable_encryption ? aws_kms_key.logs[0].arn : null

  tags = {
    Name        = "${var.project_name}-centralized-infra-logs"
    Environment = var.environment
    Type        = "Centralized"
  }
}

# ----------------------------------------------------------------------------
# LOG GROUP CENTRALIZADO - Logs de seguridad (alta retención)
# ----------------------------------------------------------------------------
resource "aws_cloudwatch_log_group" "centralized_security" {
  name              = "/aws/centralized/${var.project_name}/security"
  retention_in_days = var.retention_days_security  # 365 días compliance
  kms_key_id        = var.enable_encryption ? aws_kms_key.logs[0].arn : null

  tags = {
    Name        = "${var.project_name}-centralized-security-logs"
    Environment = var.environment
    Type        = "Centralized"
    Compliance  = "critical"
  }
}

# ----------------------------------------------------------------------------
# KMS KEY para encriptar logs (opcional, mejores prácticas)
# ----------------------------------------------------------------------------
resource "aws_kms_key" "logs" {
  count               = var.enable_encryption ? 1 : 0
  description         = "KMS key for CloudWatch Logs encryption - ${var.project_name}"
  enable_key_rotation = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow CloudWatch Logs"
        Effect = "Allow"
        Principal = {
          Service = "logs.amazonaws.com"
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:CreateGrant",
          "kms:DescribeKey"
        ]
        Resource = "*"
        Condition = {
          ArnLike = {
            "kms:EncryptionContext:aws:logs:arn" = "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/centralized/${var.project_name}/*"
          }
        }
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-logs-kms"
  }
}

resource "aws_kms_alias" "logs" {
  count         = var.enable_encryption ? 1 : 0
  name          = "alias/${var.project_name}-logs"
  target_key_id = aws_kms_key.logs[0].key_id
}

# ----------------------------------------------------------------------------
# METRIC FILTERS - Detección automática de errores críticos
# ----------------------------------------------------------------------------
resource "aws_cloudwatch_log_metric_filter" "error_5xx" {
  name           = "${var.project_name}-5xx-errors"
  log_group_name = aws_cloudwatch_log_group.centralized_app.name
  pattern        = "[time, request_id, level = ERROR, status_code = 5*, ...]"

  metric_transformation {
    name      = "Application5xxErrors"
    namespace = "${var.project_name}/Logs"
    value     = "1"
    unit      = "Count"
  }
}

resource "aws_cloudwatch_log_metric_filter" "db_connection_errors" {
  name           = "${var.project_name}-db-connection-errors"
  log_group_name = aws_cloudwatch_log_group.centralized_app.name
  pattern        = "?\"connection refused\" ?\"could not connect\" ?\"timeout\""

  metric_transformation {
    name      = "DatabaseConnectionErrors"
    namespace = "${var.project_name}/Logs"
    value     = "1"
    unit      = "Count"
  }
}

# ----------------------------------------------------------------------------
# INSIGHTS QUERIES - Consultas predefinidas para análisis
# ----------------------------------------------------------------------------
resource "aws_cloudwatch_query_definition" "top_errors" {
  name = "${var.project_name}/Top 10 Errors Last Hour"

  log_group_names = [
    aws_cloudwatch_log_group.centralized_app.name
  ]

  query_string = <<-QUERY
    fields @timestamp, @message
    | filter @message like /ERROR/
    | stats count() as error_count by @message
    | sort error_count desc
    | limit 10
  QUERY
}

resource "aws_cloudwatch_query_definition" "slow_requests" {
  name = "${var.project_name}/Slow Requests (>3s)"

  log_group_names = [
    aws_cloudwatch_log_group.centralized_app.name
  ]

  query_string = <<-QUERY
    fields @timestamp, @message, duration
    | filter duration > 3000
    | sort duration desc
    | limit 20
  QUERY
}

# ----------------------------------------------------------------------------
# DATA SOURCES
# ----------------------------------------------------------------------------
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
