# ============================================================================
# CLOUDWATCH ALARMS - CLIENT VPN
# ============================================================================

locals {
  vpn_max_connections    = 50
  vpn_auth_failures_high = 5    # Intentos de auth fallidos por minuto
  vpn_bytes_threshold    = 10737418240  # 10 GB por periodo
}

# ----------------------------------------------------------------------------
# ALARMA: Active Connections Alto
# ----------------------------------------------------------------------------
resource "aws_cloudwatch_metric_alarm" "vpn_connections_high" {
  alarm_name          = "${var.project_name}-vpn-connections-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "ActiveConnectionsCount"
  namespace           = "AWS/ClientVPN"
  period              = 300  # 5 minutos
  statistic           = "Average"
  threshold           = local.vpn_max_connections
  alarm_description   = "VPN active connections exceed ${local.vpn_max_connections}"
  alarm_actions       = [var.sns_topic_warning_arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    Endpoint = aws_ec2_client_vpn_endpoint.main.id
  }

  tags = {
    Name        = "${var.project_name}-vpn-connections-high"
    Severity    = "Warning"
    Resource    = "ClientVPN"
  }
}

# ----------------------------------------------------------------------------
# ALARMA: Authentication Failures (posible ataque)
# ----------------------------------------------------------------------------
resource "aws_cloudwatch_metric_alarm" "vpn_auth_failures" {
  alarm_name          = "${var.project_name}-vpn-auth-failures-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "AuthenticationFailures"
  namespace           = "AWS/ClientVPN"
  period              = 60  # 1 minuto
  statistic           = "Sum"
  threshold           = local.vpn_auth_failures_high
  alarm_description   = "VPN authentication failures exceed ${local.vpn_auth_failures_high} per minute (possible attack)"
  alarm_actions       = [var.sns_topic_critical_arn]
  ok_actions          = [var.sns_topic_critical_arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    Endpoint = aws_ec2_client_vpn_endpoint.main.id
  }

  tags = {
    Name        = "${var.project_name}-vpn-auth-failures"
    Severity    = "Critical"
    Resource    = "ClientVPN"
    Type        = "Security"
  }
}

# ----------------------------------------------------------------------------
# ALARMA: Ingress Bytes Alto (tráfico inusual)
# ----------------------------------------------------------------------------
resource "aws_cloudwatch_metric_alarm" "vpn_ingress_bytes_high" {
  alarm_name          = "${var.project_name}-vpn-ingress-bytes-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "IngressBytes"
  namespace           = "AWS/ClientVPN"
  period              = 300
  statistic           = "Sum"
  threshold           = local.vpn_bytes_threshold
  alarm_description   = "VPN ingress traffic is unusually high"
  alarm_actions       = [var.sns_topic_warning_arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    Endpoint = aws_ec2_client_vpn_endpoint.main.id
  }

  tags = {
    Name        = "${var.project_name}-vpn-ingress-bytes-high"
    Severity    = "Warning"
    Resource    = "ClientVPN"
  }
}

# ----------------------------------------------------------------------------
# ALARMA: Egress Bytes Alto (data exfiltration?)
# ----------------------------------------------------------------------------
resource "aws_cloudwatch_metric_alarm" "vpn_egress_bytes_high" {
  alarm_name          = "${var.project_name}-vpn-egress-bytes-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "EgressBytes"
  namespace           = "AWS/ClientVPN"
  period              = 300
  statistic           = "Sum"
  threshold           = local.vpn_bytes_threshold
  alarm_description   = "VPN egress traffic is unusually high (possible data exfiltration)"
  alarm_actions       = [var.sns_topic_critical_arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    Endpoint = aws_ec2_client_vpn_endpoint.main.id
  }

  tags = {
    Name        = "${var.project_name}-vpn-egress-bytes-high"
    Severity    = "Critical"
    Resource    = "ClientVPN"
    Type        = "Security"
  }
}

# ----------------------------------------------------------------------------
# OUTPUTS
# ----------------------------------------------------------------------------
output "vpn_alarm_names" {
  description = "Lista de nombres de alarmas de VPN para Composite Alarms"
  value = [
    aws_cloudwatch_metric_alarm.vpn_auth_failures.alarm_name,
    aws_cloudwatch_metric_alarm.vpn_egress_bytes_high.alarm_name
  ]
}

output "vpn_alarm_arns" {
  description = "ARNs de alarmas de VPN"
  value = [
    aws_cloudwatch_metric_alarm.vpn_auth_failures.arn,
    aws_cloudwatch_metric_alarm.vpn_connections_high.arn
  ]
}
