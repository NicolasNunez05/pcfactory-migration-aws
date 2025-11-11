# ============================================================================
# CLOUDWATCH ALARMS - EC2 INSTANCES
# ============================================================================
# Alarmas específicas para instancias EC2 de capa Web y App

# ----------------------------------------------------------------------------
# Variables locales para umbrales
# ----------------------------------------------------------------------------
locals {
  cpu_high_threshold      = 80
  cpu_warning_threshold   = 70
  memory_high_threshold   = 85
  memory_warning_threshold = 75
  disk_high_threshold     = 90
}

# ----------------------------------------------------------------------------
# ALARMA: CPU Utilization Alta (CRITICAL)
# ----------------------------------------------------------------------------
resource "aws_cloudwatch_metric_alarm" "ec2_cpu_high" {
  alarm_name          = "${var.project_name}-ec2-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300  # 5 minutos
  statistic           = "Average"
  threshold           = local.cpu_high_threshold
  alarm_description   = "EC2 CPU usage is above ${local.cpu_high_threshold}%"
  alarm_actions       = [var.sns_topic_critical_arn]
  ok_actions          = [var.sns_topic_critical_arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.app.name
  }

  tags = {
    Name        = "${var.project_name}-ec2-cpu-high"
    Severity    = "Critical"
    Resource    = "EC2"
    Environment = var.environment
  }
}

# ----------------------------------------------------------------------------
# ALARMA: CPU Utilization Warning
# ----------------------------------------------------------------------------
resource "aws_cloudwatch_metric_alarm" "ec2_cpu_warning" {
  alarm_name          = "${var.project_name}-ec2-cpu-warning"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = local.cpu_warning_threshold
  alarm_description   = "EC2 CPU usage is above ${local.cpu_warning_threshold}%"
  alarm_actions       = [var.sns_topic_warning_arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.app.name
  }

  tags = {
    Name        = "${var.project_name}-ec2-cpu-warning"
    Severity    = "Warning"
    Resource    = "EC2"
  }
}

# ----------------------------------------------------------------------------
# ALARMA: Status Check Failed (Instance)
# ----------------------------------------------------------------------------
resource "aws_cloudwatch_metric_alarm" "ec2_status_check_instance" {
  alarm_name          = "${var.project_name}-ec2-status-check-instance-failed"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "StatusCheckFailed_Instance"
  namespace           = "AWS/EC2"
  period              = 60  # 1 minuto
  statistic           = "Maximum"
  threshold           = 0
  alarm_description   = "EC2 instance status check failed"
  alarm_actions       = [var.sns_topic_critical_arn]
  ok_actions          = [var.sns_topic_critical_arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.app.name
  }

  tags = {
    Name        = "${var.project_name}-ec2-status-instance-failed"
    Severity    = "Critical"
    Resource    = "EC2"
  }
}

# ----------------------------------------------------------------------------
# ALARMA: Status Check Failed (System)
# ----------------------------------------------------------------------------
resource "aws_cloudwatch_metric_alarm" "ec2_status_check_system" {
  alarm_name          = "${var.project_name}-ec2-status-check-system-failed"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "StatusCheckFailed_System"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Maximum"
  threshold           = 0
  alarm_description   = "EC2 system status check failed"
  alarm_actions       = [var.sns_topic_critical_arn]
  ok_actions          = [var.sns_topic_critical_arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.app.name
  }

  tags = {
    Name        = "${var.project_name}-ec2-status-system-failed"
    Severity    = "Critical"
    Resource    = "EC2"
  }
}

# ----------------------------------------------------------------------------
# ALARMA: Memory Utilization Alta (Custom Metric de CloudWatch Agent)
# ----------------------------------------------------------------------------
resource "aws_cloudwatch_metric_alarm" "ec2_memory_high" {
  alarm_name          = "${var.project_name}-ec2-memory-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "MEMORY_USED"
  namespace           = "PCFactory/EC2"  # Custom namespace del CloudWatch Agent
  period              = 300
  statistic           = "Average"
  threshold           = local.memory_high_threshold
  alarm_description   = "EC2 Memory usage is above ${local.memory_high_threshold}%"
  alarm_actions       = [var.sns_topic_critical_arn]
  ok_actions          = [var.sns_topic_critical_arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.app.name
  }

  tags = {
    Name        = "${var.project_name}-ec2-memory-high"
    Severity    = "Critical"
    Resource    = "EC2"
  }
}

# ----------------------------------------------------------------------------
# ALARMA: Disk Utilization Alta (Custom Metric)
# ----------------------------------------------------------------------------
resource "aws_cloudwatch_metric_alarm" "ec2_disk_high" {
  alarm_name          = "${var.project_name}-ec2-disk-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "DISK_USED"
  namespace           = "PCFactory/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = local.disk_high_threshold
  alarm_description   = "EC2 Disk usage is above ${local.disk_high_threshold}%"
  alarm_actions       = [var.sns_topic_critical_arn]
  ok_actions          = [var.sns_topic_critical_arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.app.name
  }

  tags = {
    Name        = "${var.project_name}-ec2-disk-high"
    Severity    = "Critical"
    Resource    = "EC2"
  }
}

# ----------------------------------------------------------------------------
# ALARMA: Network In (Tráfico anómalo)
# ----------------------------------------------------------------------------
resource "aws_cloudwatch_metric_alarm" "ec2_network_in_anomaly" {
  alarm_name          = "${var.project_name}-ec2-network-in-anomaly"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "NetworkIn"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 10000000000  # 10 GB en 5 minutos
  alarm_description   = "EC2 Network In traffic is unusually high (possible DDoS)"
  alarm_actions       = [var.sns_topic_critical_arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.app.name
  }

  tags = {
    Name        = "${var.project_name}-ec2-network-in-anomaly"
    Severity    = "Critical"
    Resource    = "EC2"
    Type        = "Security"
  }
}

# ----------------------------------------------------------------------------
# OUTPUTS
# ----------------------------------------------------------------------------
output "ec2_alarm_names" {
  description = "Lista de nombres de alarmas de EC2 para Composite Alarms"
  value = [
    aws_cloudwatch_metric_alarm.ec2_cpu_high.alarm_name,
    aws_cloudwatch_metric_alarm.ec2_status_check_instance.alarm_name,
    aws_cloudwatch_metric_alarm.ec2_status_check_system.alarm_name,
    aws_cloudwatch_metric_alarm.ec2_memory_high.alarm_name,
    aws_cloudwatch_metric_alarm.ec2_disk_high.alarm_name
  ]
}

output "ec2_alarm_arns" {
  description = "ARNs de alarmas de EC2"
  value = [
    aws_cloudwatch_metric_alarm.ec2_cpu_high.arn,
    aws_cloudwatch_metric_alarm.ec2_memory_high.arn,
    aws_cloudwatch_metric_alarm.ec2_disk_high.arn
  ]
}
