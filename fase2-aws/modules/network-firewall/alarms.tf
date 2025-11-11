# ============================================================================
# CLOUDWATCH ALARMS - NETWORK FIREWALL
# ============================================================================

locals {
  firewall_packets_dropped_threshold = 1000  # Paquetes descartados por minuto
  firewall_invalid_packets_threshold = 100   # Paquetes inválidos por minuto
}

# ----------------------------------------------------------------------------
# ALARMA: Packets Dropped Alto
# ----------------------------------------------------------------------------
resource "aws_cloudwatch_metric_alarm" "firewall_packets_dropped" {
  alarm_name          = "${var.project_name}-firewall-packets-dropped-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "DroppedPackets"
  namespace           = "AWS/NetworkFirewall"
  period              = 60  # 1 minuto
  statistic           = "Sum"
  threshold           = local.firewall_packets_dropped_threshold
  alarm_description   = "Network Firewall dropped packets exceed ${local.firewall_packets_dropped_threshold} per minute"
  alarm_actions       = [var.sns_topic_warning_arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    FirewallName = aws_networkfirewall_firewall.main.name
  }

  tags = {
    Name        = "${var.project_name}-firewall-packets-dropped"
    Severity    = "Warning"
    Resource    = "NetworkFirewall"
  }
}

# ----------------------------------------------------------------------------
# ALARMA: Invalid Packets (posible ataque)
# ----------------------------------------------------------------------------
resource "aws_cloudwatch_metric_alarm" "firewall_invalid_packets" {
  alarm_name          = "${var.project_name}-firewall-invalid-packets-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "InvalidPackets"
  namespace           = "AWS/NetworkFirewall"
  period              = 60
  statistic           = "Sum"
  threshold           = local.firewall_invalid_packets_threshold
  alarm_description   = "Network Firewall invalid packets exceed ${local.firewall_invalid_packets_threshold} per minute (possible attack)"
  alarm_actions       = [var.sns_topic_critical_arn]
  ok_actions          = [var.sns_topic_critical_arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    FirewallName = aws_networkfirewall_firewall.main.name
  }

  tags = {
    Name        = "${var.project_name}-firewall-invalid-packets"
    Severity    = "Critical"
    Resource    = "NetworkFirewall"
    Type        = "Security"
  }
}

# ----------------------------------------------------------------------------
# ALARMA: Packets (throughput anómalo)
# ----------------------------------------------------------------------------
resource "aws_cloudwatch_metric_alarm" "firewall_packets_high" {
  alarm_name          = "${var.project_name}-firewall-packets-anomaly"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "Packets"
  namespace           = "AWS/NetworkFirewall"
  period              = 300  # 5 minutos
  statistic           = "Sum"
  threshold           = 1000000  # 1 millón de paquetes por 5 min
  alarm_description   = "Network Firewall packet throughput is anomalously high"
  alarm_actions       = [var.sns_topic_warning_arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    FirewallName = aws_networkfirewall_firewall.main.name
  }

  tags = {
    Name        = "${var.project_name}-firewall-packets-anomaly"
    Severity    = "Warning"
    Resource    = "NetworkFirewall"
  }
}

# ----------------------------------------------------------------------------
# METRIC FILTER: Alertas específicas del Firewall desde logs
# ----------------------------------------------------------------------------
resource "aws_cloudwatch_log_metric_filter" "firewall_alerts_critical" {
  name           = "${var.project_name}-firewall-alerts-critical"
  log_group_name = aws_cloudwatch_log_group.alert.name
  pattern        = "[time, alert_type=ALERT*, priority=1, ...]"  # Prioridad 1 = crítica

  metric_transformation {
    name      = "FirewallCriticalAlerts"
    namespace = "${var.project_name}/Firewall"
    value     = "1"
    unit      = "Count"
  }
}

# ----------------------------------------------------------------------------
# ALARMA: Critical Firewall Alerts desde logs
# ----------------------------------------------------------------------------
resource "aws_cloudwatch_metric_alarm" "firewall_critical_alerts" {
  alarm_name          = "${var.project_name}-firewall-critical-alerts"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "FirewallCriticalAlerts"
  namespace           = "${var.project_name}/Firewall"
  period              = 60
  statistic           = "Sum"
  threshold           = 0
  alarm_description   = "Network Firewall generated critical security alerts"
  alarm_actions       = [var.sns_topic_critical_arn]
  ok_actions          = [var.sns_topic_critical_arn]
  treat_missing_data  = "notBreaching"

  tags = {
    Name        = "${var.project_name}-firewall-critical-alerts"
    Severity    = "Critical"
    Resource    = "NetworkFirewall"
    Type        = "Security"
  }
}

# ----------------------------------------------------------------------------
# OUTPUTS
# ----------------------------------------------------------------------------
output "firewall_alarm_names" {
  description = "Lista de nombres de alarmas de Firewall para Composite Alarms"
  value = [
    aws_cloudwatch_metric_alarm.firewall_invalid_packets.alarm_name,
    aws_cloudwatch_metric_alarm.firewall_critical_alerts.alarm_name
  ]
}

output "firewall_alarm_arns" {
  description = "ARNs de alarmas de Firewall"
  value = [
    aws_cloudwatch_metric_alarm.firewall_invalid_packets.arn,
    aws_cloudwatch_metric_alarm.firewall_packets_dropped.arn
  ]
}
