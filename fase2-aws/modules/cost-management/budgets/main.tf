# =============================================================================
# MÓDULO AWS BUDGETS - GESTIÓN DE COSTOS
# =============================================================================
# Presupuestos con alertas por email y SNS para control de costos
# =============================================================================

# Data sources
data "aws_caller_identity" "current" {}

# =============================================================================
# SNS TOPIC PARA NOTIFICACIONES DE BUDGET (si no se proporciona uno)
# =============================================================================

resource "aws_sns_topic" "budget_alerts" {
  count = var.sns_topic_arn == null ? 1 : 0

  name              = "${var.project_name}-${var.environment}-budget-alerts"
  display_name      = "Budget Alerts - ${var.project_name}"
  kms_master_key_id = null

  tags = merge(
    {
      Name        = "${var.project_name}-${var.environment}-budget-alerts"
      Environment = var.environment
      Project     = var.project_name
      ManagedBy   = "Terraform"
    },
    var.tags
  )
}

# Suscripciones por email al SNS topic
resource "aws_sns_topic_subscription" "budget_email" {
  count = var.sns_topic_arn == null && length(var.notification_emails) > 0 ? length(var.notification_emails) : 0

  topic_arn = aws_sns_topic.budget_alerts[0].arn
  protocol  = "email"
  endpoint  = var.notification_emails[count.index]
}

# Variable local para determinar qué SNS topic usar
locals {
  sns_topic_arn = var.sns_topic_arn != null ? var.sns_topic_arn : (length(aws_sns_topic.budget_alerts) > 0 ? aws_sns_topic.budget_alerts[0].arn : null)
}

# =============================================================================
# PRESUPUESTO GLOBAL
# =============================================================================

resource "aws_budgets_budget" "global" {
  name         = "${var.project_name}-${var.environment}-global-budget"
  budget_type  = "COST"
  limit_amount = tostring(var.global_monthly_budget)
  limit_unit   = "USD"
  time_unit    = var.time_unit

  lifecycle {
    ignore_changes = [notification]
  }

  notification {
    comparison_operator        = var.comparison_operator
    threshold                  = var.alert_threshold_percentage
    threshold_type             = "PERCENTAGE"
    notification_type          = var.notification_type
    subscriber_email_addresses = length(var.notification_emails) > 0 ? var.notification_emails : null
    subscriber_sns_topic_arns  = local.sns_topic_arn != null ? [local.sns_topic_arn] : null
  }

  cost_types {
    include_credit             = false
    include_discount           = true
    include_other_subscription = true
    include_recurring          = true
    include_refund             = false
    include_subscription       = true
    include_support            = true
    include_tax                = true
    include_upfront            = true
    use_blended                = false
  }

  tags = var.tags
}

# =============================================================================
# PRESUPUESTO EC2
# =============================================================================

resource "aws_budgets_budget" "ec2" {
  count = var.enable_service_budgets ? 1 : 0

  name         = "${var.project_name}-${var.environment}-ec2-budget"
  budget_type  = "COST"
  limit_amount = tostring(var.ec2_monthly_budget)
  limit_unit   = "USD"
  time_unit    = var.time_unit

  time_period_start = formatdate("YYYY-MM-01_00:00", timestamp())

  lifecycle {
    ignore_changes = [notification]
  }

  cost_filter {
    name   = "Service"
    values = ["Amazon Elastic Compute Cloud - Compute"]
  }

  notification {
    comparison_operator        = var.comparison_operator
    threshold                  = var.alert_threshold_percentage
    threshold_type             = "PERCENTAGE"
    notification_type          = var.notification_type
    subscriber_email_addresses = length(var.notification_emails) > 0 ? var.notification_emails : null
    subscriber_sns_topic_arns  = local.sns_topic_arn != null ? [local.sns_topic_arn] : null
  }
}

# =============================================================================
# PRESUPUESTO RDS
# =============================================================================

resource "aws_budgets_budget" "rds" {
  count = var.enable_service_budgets ? 1 : 0

  name         = "${var.project_name}-${var.environment}-rds-budget"
  budget_type  = "COST"
  limit_amount = tostring(var.rds_monthly_budget)
  limit_unit   = "USD"
  time_unit    = var.time_unit

  time_period_start = formatdate("YYYY-MM-01_00:00", timestamp())

  lifecycle {
    ignore_changes = [notification]
  }

  cost_filter {
    name   = "Service"
    values = ["Amazon Relational Database Service"]
  }

  notification {
    comparison_operator        = var.comparison_operator
    threshold                  = var.alert_threshold_percentage
    threshold_type             = "PERCENTAGE"
    notification_type          = var.notification_type
    subscriber_email_addresses = length(var.notification_emails) > 0 ? var.notification_emails : null
    subscriber_sns_topic_arns  = local.sns_topic_arn != null ? [local.sns_topic_arn] : null
  }
}

# =============================================================================
# PRESUPUESTO S3
# =============================================================================

resource "aws_budgets_budget" "s3" {
  count = var.enable_service_budgets ? 1 : 0

  name         = "${var.project_name}-${var.environment}-s3-budget"
  budget_type  = "COST"
  limit_amount = tostring(var.s3_monthly_budget)
  limit_unit   = "USD"
  time_unit    = var.time_unit

  time_period_start = formatdate("YYYY-MM-01_00:00", timestamp())

  lifecycle {
    ignore_changes = [notification]
  }

  cost_filter {
    name   = "Service"
    values = ["Amazon Simple Storage Service"]
  }

  notification {
    comparison_operator        = var.comparison_operator
    threshold                  = var.alert_threshold_percentage
    threshold_type             = "PERCENTAGE"
    notification_type          = var.notification_type
    subscriber_email_addresses = length(var.notification_emails) > 0 ? var.notification_emails : null
    subscriber_sns_topic_arns  = local.sns_topic_arn != null ? [local.sns_topic_arn] : null
  }
}

# =============================================================================
# PRESUPUESTO ELASTICACHE
# =============================================================================

resource "aws_budgets_budget" "elasticache" {
  count = var.enable_service_budgets ? 1 : 0

  name         = "${var.project_name}-${var.environment}-elasticache-budget"
  budget_type  = "COST"
  limit_amount = tostring(var.elasticache_monthly_budget)
  limit_unit   = "USD"
  time_unit    = var.time_unit

  time_period_start = formatdate("YYYY-MM-01_00:00", timestamp())

  lifecycle {
    ignore_changes = [notification]
  }

  cost_filter {
    name   = "Service"
    values = ["Amazon ElastiCache"]
  }

  notification {
    comparison_operator        = var.comparison_operator
    threshold                  = var.alert_threshold_percentage
    threshold_type             = "PERCENTAGE"
    notification_type          = var.notification_type
    subscriber_email_addresses = length(var.notification_emails) > 0 ? var.notification_emails : null
    subscriber_sns_topic_arns  = local.sns_topic_arn != null ? [local.sns_topic_arn] : null
  }
}
