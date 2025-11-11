# ============================================================================
# CLOUDWATCH ALARMS - RDS POSTGRESQL
# ============================================================================

locals {
  rds_cpu_high_threshold         = 75
  rds_memory_low_threshold       = 1073741824  # 1 GB en bytes
  rds_connections_high_threshold = 80  # % de max_connections
  rds_storage_low_threshold      = 10  # % libre
  rds_latency_threshold          = 0.1 # 100ms
}

# ----------------------------------------------------------------------------
# ALARMA: CPU Utilization Alta
# ----------------------------------------------------------------------------
resource "aws_cloudwatch_metric_alarm" "rds_cpu_high" {
  alarm_name          = "${var.project_name}-rds-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = local.rds_cpu_high_threshold
  alarm_description   = "RDS CPU usage is above ${local.rds_cpu_high_threshold}%"
  alarm_actions       = [var.sns_topic_critical_arn]
  ok_actions          = [var.sns_topic_critical_arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.postgresql.id
  }

  tags = {
    Name        = "${var.project_name}-rds-cpu-high"
    Severity    = "Critical"
    Resource    = "RDS"
  }
}

# ----------------------------------------------------------------------------
# ALARMA: Memoria Libre Baja
# ----------------------------------------------------------------------------
resource "aws_cloudwatch_metric_alarm" "rds_memory_low" {
  alarm_name          = "${var.project_name}-rds-memory-low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "FreeableMemory"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = local.rds_memory_low_threshold
  alarm_description   = "RDS freeable memory is below 1 GB"
  alarm_actions       = [var.sns_topic_critical_arn]
  ok_actions          = [var.sns_topic_critical_arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.postgresql.id
  }

  tags = {
    Name        = "${var.project_name}-rds-memory-low"
    Severity    = "Critical"
    Resource    = "RDS"
  }
}

# ----------------------------------------------------------------------------
# ALARMA: Conexiones de Base de Datos Altas
# ----------------------------------------------------------------------------
resource "aws_cloudwatch_metric_alarm" "rds_connections_high" {
  alarm_name          = "${var.project_name}-rds-connections-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "DatabaseConnections"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 80  # Ajustar según max_connections de tu RDS
  alarm_description   = "RDS database connections are high"
  alarm_actions       = [var.sns_topic_warning_arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.postgresql.id
  }

  tags = {
    Name        = "${var.project_name}-rds-connections-high"
    Severity    = "Warning"
    Resource    = "RDS"
  }
}

# ----------------------------------------------------------------------------
# ALARMA: Espacio de Almacenamiento Bajo
# ----------------------------------------------------------------------------
resource "aws_cloudwatch_metric_alarm" "rds_storage_low" {
  alarm_name          = "${var.project_name}-rds-storage-low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  metric_name         = "FreeStorageSpace"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 10737418240  # 10 GB en bytes
  alarm_description   = "RDS free storage space is below 10 GB"
  alarm_actions       = [var.sns_topic_critical_arn]
  ok_actions          = [var.sns_topic_critical_arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.postgresql.id
  }

  tags = {
    Name        = "${var.project_name}-rds-storage-low"
    Severity    = "Critical"
    Resource    = "RDS"
  }
}

# ----------------------------------------------------------------------------
# ALARMA: Read Latency Alta
# ----------------------------------------------------------------------------
resource "aws_cloudwatch_metric_alarm" "rds_read_latency_high" {
  alarm_name          = "${var.project_name}-rds-read-latency-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "ReadLatency"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = local.rds_latency_threshold
  alarm_description   = "RDS read latency is above ${local.rds_latency_threshold * 1000}ms"
  alarm_actions       = [var.sns_topic_warning_arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.postgresql.id
  }

  tags = {
    Name        = "${var.project_name}-rds-read-latency-high"
    Severity    = "Warning"
    Resource    = "RDS"
  }
}

# ----------------------------------------------------------------------------
# ALARMA: Write Latency Alta
# ----------------------------------------------------------------------------
resource "aws_cloudwatch_metric_alarm" "rds_write_latency_high" {
  alarm_name          = "${var.project_name}-rds-write-latency-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "WriteLatency"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = local.rds_latency_threshold
  alarm_description   = "RDS write latency is above ${local.rds_latency_threshold * 1000}ms"
  alarm_actions       = [var.sns_topic_warning_arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.postgresql.id
  }

  tags = {
    Name        = "${var.project_name}-rds-write-latency-high"
    Severity    = "Warning"
    Resource    = "RDS"
  }
}

# ----------------------------------------------------------------------------
# ALARMA: Burst Balance Bajo (para GP2 volumes)
# ----------------------------------------------------------------------------
resource "aws_cloudwatch_metric_alarm" "rds_burst_balance_low" {
  alarm_name          = "${var.project_name}-rds-burst-balance-low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "BurstBalance"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 20  # % de burst balance
  alarm_description   = "RDS burst balance is below 20%"
  alarm_actions       = [var.sns_topic_warning_arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.postgresql.id
  }

  tags = {
    Name        = "${var.project_name}-rds-burst-balance-low"
    Severity    = "Warning"
    Resource    = "RDS"
  }
}

# ----------------------------------------------------------------------------
# OUTPUTS
# ----------------------------------------------------------------------------
output "rds_alarm_names" {
  description = "Lista de nombres de alarmas de RDS para Composite Alarms"
  value = [
    aws_cloudwatch_metric_alarm.rds_cpu_high.alarm_name,
    aws_cloudwatch_metric_alarm.rds_memory_low.alarm_name,
    aws_cloudwatch_metric_alarm.rds_storage_low.alarm_name
  ]
}

output "rds_alarm_arns" {
  description = "ARNs de alarmas de RDS"
  value = [
    aws_cloudwatch_metric_alarm.rds_cpu_high.arn,
    aws_cloudwatch_metric_alarm.rds_memory_low.arn,
    aws_cloudwatch_metric_alarm.rds_storage_low.arn
  ]
}
