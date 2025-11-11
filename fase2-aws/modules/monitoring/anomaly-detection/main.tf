# =============================================================================
# CLOUDWATCH ANOMALY DETECTION
# =============================================================================
# Detección automática de comportamientos anómalos
# =============================================================================

data "aws_region" "current" {}

# =============================================================================
# CPU ANOMALY DETECTION
# =============================================================================
resource "aws_cloudwatch_metric_alarm" "cpu_anomaly" {
  count = var.enable_cpu_anomaly ? 1 : 0

  alarm_name          = "${var.project_name}-${var.environment}-cpu-anomaly"
  comparison_operator = "LessThanLowerOrGreaterThanUpperThreshold"
  evaluation_periods  = var.evaluation_periods
  threshold_metric_id = "e1"
  alarm_description   = "Detecta anomalías en uso de CPU de EC2"
  alarm_actions       = [var.sns_topic_arn]
  treat_missing_data  = "notBreaching"

  metric_query {
    id          = "e1"
    expression  = "ANOMALY_DETECTION_BAND(m1, ${var.anomaly_band_width})"
    label       = "CPU Utilization (Expected)"
    return_data = true
  }

  metric_query {
    id = "m1"
    metric {
      metric_name = "CPUUtilization"
      namespace   = "AWS/EC2"
      period      = 300
      stat        = "Average"
    }
    return_data = true
  }

  tags = merge(
    {
      Name = "${var.project_name}-cpu-anomaly-detector"
    },
    var.tags
  )
}

# =============================================================================
# DATABASE CONNECTIONS ANOMALY
# =============================================================================
resource "aws_cloudwatch_metric_alarm" "db_connections_anomaly" {
  count = var.enable_db_anomaly ? 1 : 0

  alarm_name          = "${var.project_name}-${var.environment}-db-connections-anomaly"
  comparison_operator = "LessThanLowerOrGreaterThanUpperThreshold"
  evaluation_periods  = var.evaluation_periods
  threshold_metric_id = "e1"
  alarm_description   = "Detecta anomalías en conexiones RDS"
  alarm_actions       = [var.sns_topic_arn]
  treat_missing_data  = "notBreaching"

  metric_query {
    id          = "e1"
    expression  = "ANOMALY_DETECTION_BAND(m1, ${var.anomaly_band_width})"
    label       = "Database Connections (Expected)"
    return_data = true
  }

  metric_query {
    id = "m1"
    metric {
      metric_name = "DatabaseConnections"
      namespace   = "AWS/RDS"
      period      = 300
      stat        = "Average"
    }
    return_data = true
  }

  tags = merge(
    {
      Name = "${var.project_name}-db-anomaly-detector"
    },
    var.tags
  )
}

# =============================================================================
# NETWORK TRAFFIC ANOMALY
# =============================================================================
resource "aws_cloudwatch_metric_alarm" "network_in_anomaly" {
  count = var.enable_network_anomaly ? 1 : 0

  alarm_name          = "${var.project_name}-${var.environment}-network-in-anomaly"
  comparison_operator = "LessThanLowerOrGreaterThanUpperThreshold"
  evaluation_periods  = var.evaluation_periods
  threshold_metric_id = "e1"
  alarm_description   = "Detecta anomalías en tráfico de red entrante"
  alarm_actions       = [var.sns_topic_arn]
  treat_missing_data  = "notBreaching"

  metric_query {
    id          = "e1"
    expression  = "ANOMALY_DETECTION_BAND(m1, ${var.anomaly_band_width})"
    label       = "Network In (Expected)"
    return_data = true
  }

  metric_query {
    id = "m1"
    metric {
      metric_name = "NetworkIn"
      namespace   = "AWS/EC2"
      period      = 300
      stat        = "Sum"
    }
    return_data = true
  }

  tags = merge(
    {
      Name = "${var.project_name}-network-anomaly-detector"
    },
    var.tags
  )
}

# =============================================================================
# APPLICATION REQUESTS ANOMALY
# =============================================================================
resource "aws_cloudwatch_metric_alarm" "request_count_anomaly" {
  count = var.enable_request_anomaly ? 1 : 0

  alarm_name          = "${var.project_name}-${var.environment}-request-anomaly"
  comparison_operator = "LessThanLowerOrGreaterThanUpperThreshold"
  evaluation_periods  = var.evaluation_periods
  threshold_metric_id = "e1"
  alarm_description   = "Detecta anomalías en tráfico de aplicación (ALB)"
  alarm_actions       = [var.sns_topic_arn]
  treat_missing_data  = "notBreaching"

  metric_query {
    id          = "e1"
    expression  = "ANOMALY_DETECTION_BAND(m1, ${var.anomaly_band_width})"
    label       = "Request Count (Expected)"
    return_data = true
  }

  metric_query {
    id = "m1"
    metric {
      metric_name = "RequestCount"
      namespace   = "AWS/ApplicationELB"
      period      = 300
      stat        = "Sum"
    }
    return_data = true
  }

  tags = merge(
    {
      Name = "${var.project_name}-request-anomaly-detector"
    },
    var.tags
  )
}

# =============================================================================
# REDIS CACHE ANOMALY
# =============================================================================
resource "aws_cloudwatch_metric_alarm" "redis_cpu_anomaly" {
  alarm_name          = "${var.project_name}-${var.environment}-redis-cpu-anomaly"
  comparison_operator = "LessThanLowerOrGreaterThanUpperThreshold"
  evaluation_periods  = var.evaluation_periods
  threshold_metric_id = "e1"
  alarm_description   = "Detecta anomalías en uso de CPU de Redis"
  alarm_actions       = [var.sns_topic_arn]
  treat_missing_data  = "notBreaching"

  metric_query {
    id          = "e1"
    expression  = "ANOMALY_DETECTION_BAND(m1, ${var.anomaly_band_width})"
    label       = "Redis CPU (Expected)"
    return_data = true
  }

  metric_query {
    id = "m1"
    metric {
      metric_name = "CPUUtilization"
      namespace   = "AWS/ElastiCache"
      period      = 300
      stat        = "Average"
    }
    return_data = true
  }

  tags = merge(
    {
      Name = "${var.project_name}-redis-anomaly-detector"
    },
    var.tags
  )
}
