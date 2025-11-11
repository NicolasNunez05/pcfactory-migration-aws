# ============================================================================
# SNS TOPICS PARA NOTIFICACIONES DE ALARMAS
# ============================================================================
# Este módulo crea los SNS topics para recibir notificaciones de CloudWatch Alarms
# Estructura de 3 topics por severidad: Critical, Warning, Info

# ----------------------------------------------------------------------------
# SNS TOPIC - CRITICAL (Email + SMS)
# ----------------------------------------------------------------------------
resource "aws_sns_topic" "critical" {
  name              = "${var.project_name}-alarms-critical"
  display_name      = "PCFactory Critical Alarms"
  delivery_policy   = jsonencode({
    http = {
      defaultHealthyRetryPolicy = {
        minDelayTarget     = 20
        maxDelayTarget     = 20
        numRetries         = 3
        numMaxDelayRetries = 0
        numNoDelayRetries  = 0
        numMinDelayRetries = 0
        backoffFunction    = "linear"
      }
    }
  })

  tags = {
    Name        = "${var.project_name}-sns-critical"
    Environment = var.environment
    Severity    = "Critical"
  }
}

# Suscripción Email para Critical
resource "aws_sns_topic_subscription" "critical_email" {
  topic_arn = aws_sns_topic.critical.arn
  protocol  = "email"
  endpoint  = var.email_endpoint
}

# Suscripción SMS para Critical (Chile +569)
resource "aws_sns_topic_subscription" "critical_sms" {
  topic_arn = aws_sns_topic.critical.arn
  protocol  = "sms"
  endpoint  = var.sms_endpoint
}

# ----------------------------------------------------------------------------
# SNS TOPIC - WARNING (Solo Email)
# ----------------------------------------------------------------------------
resource "aws_sns_topic" "warning" {
  name         = "${var.project_name}-alarms-warning"
  display_name = "PCFactory Warning Alarms"

  tags = {
    Name        = "${var.project_name}-sns-warning"
    Environment = var.environment
    Severity    = "Warning"
  }
}

# Suscripción Email para Warning
resource "aws_sns_topic_subscription" "warning_email" {
  topic_arn = aws_sns_topic.warning.arn
  protocol  = "email"
  endpoint  = var.email_endpoint
}

# ----------------------------------------------------------------------------
# SNS TOPIC - INFO (Email con batching)
# ----------------------------------------------------------------------------
resource "aws_sns_topic" "info" {
  name         = "${var.project_name}-alarms-info"
  display_name = "PCFactory Info Notifications"

  tags = {
    Name        = "${var.project_name}-sns-info"
    Environment = var.environment
    Severity    = "Info"
  }
}

# Suscripción Email para Info
resource "aws_sns_topic_subscription" "info_email" {
  topic_arn = aws_sns_topic.info.arn
  protocol  = "email"
  endpoint  = var.email_endpoint
}

# ----------------------------------------------------------------------------
# SNS TOPIC POLICY - Permitir CloudWatch publicar
# ----------------------------------------------------------------------------
data "aws_iam_policy_document" "sns_topic_policy" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["cloudwatch.amazonaws.com"]
    }
    actions = [
      "SNS:Publish"
    ]
    resources = [
      aws_sns_topic.critical.arn,
      aws_sns_topic.warning.arn,
      aws_sns_topic.info.arn
    ]
  }

  statement {
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    actions = [
      "SNS:GetTopicAttributes",
      "SNS:SetTopicAttributes",
      "SNS:AddPermission",
      "SNS:RemovePermission",
      "SNS:DeleteTopic",
      "SNS:Subscribe",
      "SNS:ListSubscriptionsByTopic",
      "SNS:Publish"
    ]
    resources = [
      aws_sns_topic.critical.arn,
      aws_sns_topic.warning.arn,
      aws_sns_topic.info.arn
    ]
    condition {
      test     = "StringEquals"
      variable = "AWS:SourceOwner"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }
}

resource "aws_sns_topic_policy" "critical" {
  arn = aws_sns_topic.critical.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid    = "AllowCloudWatchPublish"
      Effect = "Allow"
      Principal = {
        Service = "cloudwatch.amazonaws.com"
      }
      Action   = "SNS:Publish"
      Resource = aws_sns_topic.critical.arn
    }]
  })
}

resource "aws_sns_topic_policy" "warning" {
  arn = aws_sns_topic.warning.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid    = "AllowCloudWatchPublish"
      Effect = "Allow"
      Principal = {
        Service = "cloudwatch.amazonaws.com"
      }
      Action   = "SNS:Publish"
      Resource = aws_sns_topic.warning.arn
    }]
  })
}

resource "aws_sns_topic_policy" "info" {
  arn = aws_sns_topic.info.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid    = "AllowCloudWatchPublish"
      Effect = "Allow"
      Principal = {
        Service = "cloudwatch.amazonaws.com"
      }
      Action   = "SNS:Publish"
      Resource = aws_sns_topic.info.arn
    }]
  })
}

# ----------------------------------------------------------------------------
# DATA SOURCES
# ----------------------------------------------------------------------------
data "aws_caller_identity" "current" {}
