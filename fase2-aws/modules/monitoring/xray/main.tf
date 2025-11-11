# ============================================================================
# AWS X-RAY - DISTRIBUTED TRACING
# ============================================================================
# Habilita rastreo distribuido de requests en la aplicación Flask
# Permite análisis de performance, debugging y detección de cuellos de botella

# ----------------------------------------------------------------------------
# X-RAY SAMPLING RULE - Control de qué trazas capturar
# ----------------------------------------------------------------------------
resource "aws_xray_sampling_rule" "default" {
  rule_name      = "${substr(var.project_name, 0, 15)}-default"  # Máximo 32 caracteres
  priority = 9999
  version        = 1
  reservoir_size = 1
  fixed_rate     = 0.05
  url_path       = "*"
  host           = "*"
  http_method    = "*"
  service_type   = "*"
  service_name   = "*"
  resource_arn   = "*"

  attributes = {
    Environment = var.environment
  }

  tags = {
    Name        = "${var.project_name}-xray-sampling"
    Environment = var.environment
  }
}


# Sampling rule para endpoints críticos (100% sampling)
resource "aws_xray_sampling_rule" "critical_endpoints" {
  rule_name      = "${substr(var.project_name, 0, 15)}-critical" # Máximo 32 caracteres
  priority       = 9999  
  version        = 1
  reservoir_size = 5
  fixed_rate     = 0.10
  url_path       = "/api/*"
  host           = "*"
  http_method    = "*"
  service_type   = "*"
  service_name   = "*"
  resource_arn   = "*"

  attributes = {
    Environment = var.environment
    Critical    = "true"
  }

  tags = {
    Name     = "${var.project_name}-xray-critical"
    Priority = "High"
  }
}



# Sampling rule para health checks (reducido al 1%)
resource "aws_xray_sampling_rule" "health_checks" {
  rule_name      = "${substr(var.project_name, 0, 15)}-health"  # Máximo 32 caracteres
  priority       = 5000
  version        = 1
  reservoir_size = 1
  fixed_rate     = 0.01  # Corregido de 0.0 a 0.01 para que represente el 1%
  url_path       = "/health"
  host           = "*"
  http_method    = "GET"
  service_type   = "*"
  service_name   = "*"
  resource_arn   = "*"

  tags = {
    Name = "${var.project_name}-xray-healthcheck"
    Type = "HealthCheck"
  }
}

# ----------------------------------------------------------------------------
# X-RAY GROUP - Agrupación lógica de trazas
# ----------------------------------------------------------------------------
resource "aws_xray_group" "app_errors" {
  group_name        = "${var.project_name}-app-errors"
  filter_expression = "service(\"${var.project_name}-flask\") AND error = true"

  insights_configuration {
    insights_enabled      = true
    notifications_enabled = var.enable_xray_insights
  }

  tags = {
    Name = "${var.project_name}-xray-errors"
    Type = "ErrorTracing"
  }
}

resource "aws_xray_group" "slow_requests" {
  group_name = "pcf-migration-slow-reqs"  # 24 chars
  filter_expression = "service(\"${var.project_name}-flask\") AND responsetime > 3"

  insights_configuration {
    insights_enabled      = true
    notifications_enabled = var.enable_xray_insights
  }

  tags = {
    Name = "${var.project_name}-xray-slow"
    Type = "PerformanceTracing"
  }
}

# ----------------------------------------------------------------------------
# IAM POLICY para X-Ray (agregar a EC2 role)
# ----------------------------------------------------------------------------
data "aws_iam_policy_document" "xray" {
  statement {
    effect = "Allow"
    actions = [
      "xray:PutTraceSegments",
      "xray:PutTelemetryRecords",
      "xray:GetSamplingRules",
      "xray:GetSamplingTargets",
      "xray:GetSamplingStatisticSummaries"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "xray" {
  name        = "${var.project_name}-xray-policy"
  description = "Permite a EC2 enviar trazas a X-Ray"
  policy      = data.aws_iam_policy_document.xray.json

  tags = {
    Name = "${var.project_name}-xray-policy"
  }
}



# ----------------------------------------------------------------------------
# CLOUDWATCH ALARMS - X-Ray Insights
# ----------------------------------------------------------------------------
# Alarma: Tasa de errores alta detectada por X-Ray
resource "aws_cloudwatch_metric_alarm" "xray_error_rate_high" {
  count = var.enable_xray_alarms ? 1 : 0

  alarm_name          = "${var.project_name}-xray-error-rate-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "FaultRate"
  namespace           = "AWS/XRay"
  period              = 300
  statistic           = "Average"
  threshold           = 5  # 5% de requests con errores
  alarm_description   = "X-Ray detected high error rate in application"
  alarm_actions       = var.enable_xray_alarms ? [var.sns_topic_critical_arn] : []
  treat_missing_data  = "notBreaching"

  dimensions = {
    ServiceName = "${var.project_name}-flask"
  }

  tags = {
    Name     = "${var.project_name}-xray-error-rate"
    Severity = "Critical"
    Source   = "XRay"
  }
}

# Alarma: Latencia alta detectada por X-Ray
resource "aws_cloudwatch_metric_alarm" "xray_latency_high" {
  count = var.enable_xray_alarms ? 1 : 0

  alarm_name          = "${var.project_name}-xray-latency-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "ResponseTime"
  namespace           = "AWS/XRay"
  period              = 300
  statistic           = "Average"
  threshold           = 3  # 3 segundos
  alarm_description   = "X-Ray detected high response time"
  alarm_actions       = var.enable_xray_alarms ? [var.sns_topic_warning_arn] : []
  treat_missing_data  = "notBreaching"

  dimensions = {
    ServiceName = "${var.project_name}-flask"
  }

  tags = {
    Name     = "${var.project_name}-xray-latency"
    Severity = "Warning"
    Source   = "XRay"
  }
}
