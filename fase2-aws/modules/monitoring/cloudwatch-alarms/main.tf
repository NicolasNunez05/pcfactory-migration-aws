# ============================================================================
# CLOUDWATCH COMPOSITE ALARMS
# ============================================================================
# Las Composite Alarms permiten crear alarmas de alto nivel que agrupan
# múltiples alarmas individuales. Útil para tener vistas agregadas.

# ----------------------------------------------------------------------------
# COMPOSITE ALARM - EC2 Health (todas las instancias)
# ----------------------------------------------------------------------------
resource "aws_cloudwatch_composite_alarm" "ec2_health_critical" {
  alarm_name          = "${var.project_name}-ec2-health-critical"
  alarm_description   = "EC2 instances in critical state (CPU, Memory, or Status Check failed)"
  actions_enabled     = true
  alarm_actions       = [var.sns_topic_critical_arn]
  ok_actions          = [var.sns_topic_critical_arn]

  # Se dispara si CUALQUIERA de las alarmas individuales está en ALARM
  alarm_rule = join(" OR ", [
    for alarm_name in var.ec2_alarm_names : 
    "ALARM(${alarm_name})"
  ])

  tags = {
    Name        = "${var.project_name}-ec2-composite-critical"
    Environment = var.environment
    Type        = "Composite"
    Severity    = "Critical"
  }
}

# ----------------------------------------------------------------------------
# COMPOSITE ALARM - RDS Health
# ----------------------------------------------------------------------------
resource "aws_cloudwatch_composite_alarm" "rds_health_critical" {
  alarm_name          = "${var.project_name}-rds-health-critical"
  alarm_description   = "RDS database in critical state"
  actions_enabled     = true
  alarm_actions       = [var.sns_topic_critical_arn]
  ok_actions          = [var.sns_topic_critical_arn]

  alarm_rule = join(" OR ", [
    for alarm_name in var.rds_alarm_names : 
    "ALARM(${alarm_name})"
  ])

  tags = {
    Name        = "${var.project_name}-rds-composite-critical"
    Environment = var.environment
    Type        = "Composite"
    Severity    = "Critical"
  }
}

# ----------------------------------------------------------------------------
# COMPOSITE ALARM - Application Health (EC2 + RDS + ALB)
# ----------------------------------------------------------------------------
resource "aws_cloudwatch_composite_alarm" "application_health" {
  alarm_name          = "${var.project_name}-application-health-critical"
  alarm_description   = "Overall application health (EC2 + RDS + ALB)"
  actions_enabled     = true
  alarm_actions       = [var.sns_topic_critical_arn]
  ok_actions          = [var.sns_topic_critical_arn]

  # Se dispara si EC2 Y RDS están en alarma simultáneamente
  alarm_rule = "ALARM(${aws_cloudwatch_composite_alarm.ec2_health_critical.alarm_name}) AND ALARM(${aws_cloudwatch_composite_alarm.rds_health_critical.alarm_name})"

  tags = {
    Name        = "${var.project_name}-app-composite-critical"
    Environment = var.environment
    Type        = "Composite"
    Severity    = "Critical"
    Scope       = "Application"
  }
}

# ----------------------------------------------------------------------------
# COMPOSITE ALARM - Infrastructure Health (Networking + Security)
# ----------------------------------------------------------------------------
resource "aws_cloudwatch_composite_alarm" "infrastructure_health" {
  count = length(var.vpn_alarm_names) > 0 && length(var.firewall_alarm_names) > 0 ? 1 : 0

  alarm_name          = "${var.project_name}-infrastructure-health-critical"
  alarm_description   = "Infrastructure health (VPN + Firewall)"
  actions_enabled     = true
  alarm_actions       = [var.sns_topic_critical_arn]

  alarm_rule = join(" OR ", concat(
    [for alarm_name in var.vpn_alarm_names : "ALARM(${alarm_name})"],
    [for alarm_name in var.firewall_alarm_names : "ALARM(${alarm_name})"]
  ))

  tags = {
    Name        = "${var.project_name}-infra-composite-critical"
    Environment = var.environment
    Type        = "Composite"
    Severity    = "Critical"
    Scope       = "Infrastructure"
  }
}
