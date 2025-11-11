# ============================================================================
# VPC FLOW LOGS
# ============================================================================
# Captura tráfico de red en la VPC para análisis de seguridad y troubleshooting
# Estrategia: VPC-level + subnet-level en zonas críticas

# ----------------------------------------------------------------------------
# IAM ROLE para VPC Flow Logs
# ----------------------------------------------------------------------------
resource "aws_iam_role" "flow_logs" {
  name = "${var.project_name}-vpc-flow-logs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-flow-logs-role"
  }
}

# IAM Policy para escribir logs
resource "aws_iam_role_policy" "flow_logs" {
  name = "${var.project_name}-flow-logs-policy"
  role = aws_iam_role.flow_logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Resource = "*"
      }
    ]
  })
}

# ----------------------------------------------------------------------------
# LOG GROUP para VPC Flow Logs (nivel VPC)
# ----------------------------------------------------------------------------
resource "aws_cloudwatch_log_group" "vpc_flow_logs" {
  name              = "/aws/vpc/${var.project_name}/flow-logs"
  retention_in_days = var.retention_days
  kms_key_id        = var.enable_encryption ? var.kms_key_id : null

  tags = {
    Name        = "${var.project_name}-vpc-flow-logs"
    Type        = "VPCFlowLogs"
    Scope       = "VPC-Wide"
    Environment = var.environment
  }
}

# ----------------------------------------------------------------------------
# VPC FLOW LOG - Nivel VPC Completa
# ----------------------------------------------------------------------------
resource "aws_flow_log" "vpc_main" {
  vpc_id          = var.vpc_id
  traffic_type    = var.traffic_type  # ACCEPT, REJECT, or ALL
  iam_role_arn    = aws_iam_role.flow_logs.arn
  log_destination_type = "cloud-watch-logs"
  log_destination      = aws_cloudwatch_log_group.vpc_flow_logs.arn

  log_format = var.custom_log_format ? var.log_format : null

  tags = {
    Name        = "${var.project_name}-vpc-flow-log"
    Scope       = "VPC"
    TrafficType = var.traffic_type
  }
}

# ----------------------------------------------------------------------------
# LOG GROUPS para Subnets específicas (públicas)
# ----------------------------------------------------------------------------
resource "aws_cloudwatch_log_group" "subnet_flow_logs" {
  count = var.enable_subnet_logs ? length(var.public_subnet_ids) : 0
  
  name              = "/aws/vpc/${var.project_name}/subnet/${var.public_subnet_ids[count.index]}/flow-logs"
  retention_in_days = var.retention_days_subnets
  kms_key_id        = var.kms_key_id

  tags = {
  Name        = "${var.project_name}-subnet-${var.public_subnet_ids[count.index]}-flow-logs"
  Environment = var.environment
  SubnetId    = var.public_subnet_ids[count.index]
  Project     = var.project_name
}
}


# ----------------------------------------------------------------------------
# FLOW LOGS para Subnets Públicas (granularidad adicional)
# ----------------------------------------------------------------------------
resource "aws_flow_log" "subnets_public" {
  count = var.enable_subnet_logs ? length(var.public_subnet_ids) : 0

  traffic_type         = "ALL"
  subnet_id            = var.public_subnet_ids[count.index]
  log_destination      = aws_cloudwatch_log_group.subnet_flow_logs[count.index].arn
  log_destination_type = "cloud-watch-logs"
  iam_role_arn         = aws_iam_role.flow_logs.arn

  tags = {
    Name        = "${var.project_name}-subnet-${var.public_subnet_ids[count.index]}-flow-log"
    Environment = var.environment
    Project     = var.project_name
  }
}

# ----------------------------------------------------------------------------
# METRIC FILTERS - Detección de anomalías de red
# ----------------------------------------------------------------------------

# Metric Filter: Rejected Connections (posible ataque)
resource "aws_cloudwatch_log_metric_filter" "rejected_connections" {
  name           = "${var.project_name}-rejected-connections"
  log_group_name = aws_cloudwatch_log_group.vpc_flow_logs.name
  pattern        = "[version, account, eni, source, destination, srcport, destport, protocol, packets, bytes, windowstart, windowend, action=REJECT, flowlogstatus]"

  metric_transformation {
    name      = "RejectedConnections"
    namespace = "${var.project_name}/VPC"
    value     = "1"
    unit      = "Count"
  }
}

# Metric Filter: SSH Attempts externos (puerto 22)
resource "aws_cloudwatch_log_metric_filter" "ssh_attempts" {
  name           = "${var.project_name}-ssh-attempts"
  log_group_name = aws_cloudwatch_log_group.vpc_flow_logs.name
  pattern        = "[version, account, eni, source, destination, srcport, destport=22, protocol=6, packets, bytes, windowstart, windowend, action, flowlogstatus]"

  metric_transformation {
    name      = "SSHAttempts"
    namespace = "${var.project_name}/VPC"
    value     = "1"
    unit      = "Count"
  }
}

# Metric Filter: RDP Attempts (puerto 3389)
resource "aws_cloudwatch_log_metric_filter" "rdp_attempts" {
  name           = "${var.project_name}-rdp-attempts"
  log_group_name = aws_cloudwatch_log_group.vpc_flow_logs.name
  pattern        = "[version, account, eni, source, destination, srcport, destport=3389, protocol=6, packets, bytes, windowstart, windowend, action, flowlogstatus]"

  metric_transformation {
    name      = "RDPAttempts"
    namespace = "${var.project_name}/VPC"
    value     = "1"
    unit      = "Count"
  }
}

# Metric Filter: Tráfico alto anómalo (>100 MB en ventana)
resource "aws_cloudwatch_log_metric_filter" "high_traffic" {
  name           = "${var.project_name}-high-traffic"
  log_group_name = aws_cloudwatch_log_group.vpc_flow_logs.name
  pattern        = "[version, account, eni, source, destination, srcport, destport, protocol, packets, bytes>100000000, windowstart, windowend, action, flowlogstatus]"

  metric_transformation {
    name      = "HighTrafficFlows"
    namespace = "${var.project_name}/VPC"
    value     = "1"
    unit      = "Count"
  }
}

# ----------------------------------------------------------------------------
# ALARMAS - Anomalías de red
# ----------------------------------------------------------------------------

# Alarma: Rejected Connections Alto
resource "aws_cloudwatch_metric_alarm" "rejected_connections_high" {
  alarm_name          = "${var.project_name}-rejected-connections-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "RejectedConnections"
  namespace           = "${var.project_name}/VPC"
  period              = 300  # 5 minutos
  statistic           = "Sum"
  threshold           = 100  # Más de 100 conexiones rechazadas en 5 min
  alarm_description   = "High number of rejected connections detected (possible attack)"
  alarm_actions       = [var.sns_topic_critical_arn]
  treat_missing_data  = "notBreaching"

  tags = {
    Name     = "${var.project_name}-rejected-connections-alarm"
    Severity = "Critical"
    Type     = "Security"
  }
}

# Alarma: SSH Attempts anómalos
resource "aws_cloudwatch_metric_alarm" "ssh_attempts_high" {
  alarm_name          = "${var.project_name}-ssh-attempts-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "SSHAttempts"
  namespace           = "${var.project_name}/VPC"
  period              = 300
  statistic           = "Sum"
  threshold           = 50  # Más de 50 intentos SSH en 5 min
  alarm_description   = "High number of SSH connection attempts detected"
  alarm_actions       = [var.sns_topic_warning_arn]
  treat_missing_data  = "notBreaching"

  tags = {
    Name     = "${var.project_name}-ssh-attempts-alarm"
    Severity = "Warning"
    Type     = "Security"
  }
}
