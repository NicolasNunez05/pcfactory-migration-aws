# ============================================================================
# CLOUDWATCH ALARMS - APPLICATION LOAD BALANCER
# ============================================================================

locals {
  alb_5xx_threshold       = 10   # Count de errores 5xx por minuto
  alb_4xx_threshold       = 50   # Count de errores 4xx por minuto
  alb_response_time       = 3    # Segundos
  alb_unhealthy_threshold = 1    # Número de hosts unhealthy
}

# ----------------------------------------------------------------------------
# ALARMA: Target 5XX Errors (Backend errors)
# ----------------------------------------------------------------------------
resource "aws_cloudwatch_metric_alarm" "alb_target_5xx" {
  alarm_name          = "${var.project_name}-alb-target-5xx-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 60  # 1 minuto
  statistic           = "Sum"
  threshold           = local.alb_5xx_threshold
  alarm_description   = "ALB target 5XX errors exceed ${local.alb_5xx_threshold} per minute"
  alarm_actions       = [var.sns_topic_critical_arn]
  ok_actions          = [var.sns_topic_critical_arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = aws_lb.main.arn_suffix
  }

  tags = {
    Name        = "${var.project_name}-alb-target-5xx"
    Severity    = "Critical"
    Resource    = "ALB"
  }
}

# ----------------------------------------------------------------------------
# ALARMA: Target 4XX Errors (Client errors)
# ----------------------------------------------------------------------------
resource "aws_cloudwatch_metric_alarm" "alb_target_4xx" {
  alarm_name          = "${var.project_name}-alb-target-4xx-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "HTTPCode_Target_4XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Sum"
  threshold           = local.alb_4xx_threshold
  alarm_description   = "ALB target 4XX errors exceed ${local.alb_4xx_threshold} per minute"
  alarm_actions       = [var.sns_topic_warning_arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = aws_lb.main.arn_suffix
  }

  tags = {
    Name        = "${var.project_name}-alb-target-4xx"
    Severity    = "Warning"
    Resource    = "ALB"
  }
}

# ----------------------------------------------------------------------------
# ALARMA: Target Response Time Alto
# ----------------------------------------------------------------------------
resource "aws_cloudwatch_metric_alarm" "alb_response_time_high" {
  alarm_name          = "${var.project_name}-alb-response-time-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "TargetResponseTime"
  namespace           = "AWS/ApplicationELB"
  period              = 300  # 5 minutos
  statistic           = "Average"
  threshold           = local.alb_response_time
  alarm_description   = "ALB target response time is above ${local.alb_response_time} seconds"
  alarm_actions       = [var.sns_topic_warning_arn]
  ok_actions          = [var.sns_topic_warning_arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = aws_lb.main.arn_suffix
  }

  tags = {
    Name        = "${var.project_name}-alb-response-time-high"
    Severity    = "Warning"
    Resource    = "ALB"
  }
}

# ----------------------------------------------------------------------------
# ALARMA: Unhealthy Host Count
# ----------------------------------------------------------------------------
resource "aws_cloudwatch_metric_alarm" "alb_unhealthy_hosts" {
  alarm_name          = "${var.project_name}-alb-unhealthy-hosts"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "UnHealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Maximum"
  threshold           = local.alb_unhealthy_threshold
  alarm_description   = "ALB has unhealthy targets"
  alarm_actions       = [var.sns_topic_critical_arn]
  ok_actions          = [var.sns_topic_critical_arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = aws_lb.main.arn_suffix
    TargetGroup  = aws_lb_target_group.app.arn_suffix
  }

  tags = {
    Name        = "${var.project_name}-alb-unhealthy-hosts"
    Severity    = "Critical"
    Resource    = "ALB"
  }
}

# ----------------------------------------------------------------------------
# ALARMA: Healthy Host Count Bajo (todos los targets caídos)
# ----------------------------------------------------------------------------
resource "aws_cloudwatch_metric_alarm" "alb_no_healthy_hosts" {
  alarm_name          = "${var.project_name}-alb-no-healthy-hosts"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  metric_name         = "HealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Minimum"
  threshold           = 1
  alarm_description   = "ALB has NO healthy targets - SERVICE DOWN"
  alarm_actions       = [var.sns_topic_critical_arn]
  ok_actions          = [var.sns_topic_critical_arn]
  treat_missing_data  = "breaching"  # Tratar missing data como alarma

  dimensions = {
    LoadBalancer = aws_lb.main.arn_suffix
    TargetGroup  = aws_lb_target_group.app.arn_suffix
  }

  tags = {
    Name        = "${var.project_name}-alb-no-healthy-hosts"
    Severity    = "Critical"
    Resource    = "ALB"
    Type        = "Availability"
  }
}

# ----------------------------------------------------------------------------
# ALARMA: Target Connection Errors
# ----------------------------------------------------------------------------
resource "aws_cloudwatch_metric_alarm" "alb_connection_errors" {
  alarm_name          = "${var.project_name}-alb-connection-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "TargetConnectionErrorCount"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Sum"
  threshold           = 5
  alarm_description   = "ALB target connection errors are high"
  alarm_actions       = [var.sns_topic_warning_arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = aws_lb.main.arn_suffix
  }

  tags = {
    Name        = "${var.project_name}-alb-connection-errors"
    Severity    = "Warning"
    Resource    = "ALB"
  }
}

# ----------------------------------------------------------------------------
# ALARMA: Rejected Connection Count (ALB saturado)
# ----------------------------------------------------------------------------
resource "aws_cloudwatch_metric_alarm" "alb_rejected_connections" {
  alarm_name          = "${var.project_name}-alb-rejected-connections"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "RejectedConnectionCount"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Sum"
  threshold           = 0
  alarm_description   = "ALB is rejecting connections (capacity reached)"
  alarm_actions       = [var.sns_topic_critical_arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = aws_lb.main.arn_suffix
  }

  tags = {
    Name        = "${var.project_name}-alb-rejected-connections"
    Severity    = "Critical"
    Resource    = "ALB"
    Type        = "Capacity"
  }
}

# ----------------------------------------------------------------------------
# OUTPUTS
# ----------------------------------------------------------------------------
output "alb_alarm_names" {
  description = "Lista de nombres de alarmas de ALB para Composite Alarms"
  value = [
    aws_cloudwatch_metric_alarm.alb_target_5xx.alarm_name,
    aws_cloudwatch_metric_alarm.alb_unhealthy_hosts.alarm_name,
    aws_cloudwatch_metric_alarm.alb_no_healthy_hosts.alarm_name
  ]
}

output "alb_alarm_arns" {
  description = "ARNs de alarmas de ALB"
  value = [
    aws_cloudwatch_metric_alarm.alb_target_5xx.arn,
    aws_cloudwatch_metric_alarm.alb_response_time_high.arn,
    aws_cloudwatch_metric_alarm.alb_no_healthy_hosts.arn
  ]
}
