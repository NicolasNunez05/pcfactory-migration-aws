# ============================================================================
# CLOUDWATCH DASHBOARDS
# ============================================================================
# Dashboards especializados para visualización de infraestructura
# - Overview: Métricas clave de toda la infraestructura
# - Networking: VPC, VPN, ALB, Flow Logs
# - Compute: EC2 instancias
# - Database: RDS PostgreSQL
# - Security: VPN, Firewall, logs de seguridad

# Variables locales para garantizar tipos string en dashboards
locals {
  asg_name_str             = tostring(var.asg_name)
  db_instance_id_str       = tostring(var.db_instance_id)
  alb_arn_suffix_str       = tostring(var.alb_arn_suffix)
  target_group_arn_suffix_str = tostring(var.target_group_arn_suffix)
  vpn_endpoint_id_str      = tostring(var.vpn_endpoint_id)
  firewall_name_str        = tostring(var.firewall_name)
  project_name_str         = tostring(var.project_name)
}

# ----------------------------------------------------------------------------
# DASHBOARD 1: OVERVIEW (Alto nivel)
# ----------------------------------------------------------------------------
resource "aws_cloudwatch_dashboard" "overview" {
  dashboard_name = "${var.project_name}-overview"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        width  = 8
        height = 6
        x      = 0
        y      = 0
        properties = {
          title   = "EC2 Auto Scaling Group Health"
          region  = var.aws_region
          metrics = [
            ["AWS/AutoScaling", "GroupDesiredCapacity", "AutoScalingGroupName", local.asg_name_str, { stat = "Average", label = "Desired" }],
            [".", "GroupInServiceInstances", ".", ".", { stat = "Average", label = "InService" }],
            [".", "GroupMinSize", ".", ".", { stat = "Average", label = "Min" }],
            [".", "GroupMaxSize", ".", ".", { stat = "Average", label = "Max" }]
          ]
          period = 300
          stat   = "Average"
          yAxis = {
            left = { min = 0 }
          }
        }
      },
      {
        type   = "metric"
        width  = 8
        height = 6
        x      = 8
        y      = 0
        properties = {
          title   = "RDS Database Health"
          region  = var.aws_region
          metrics = [
            ["AWS/RDS", "CPUUtilization", "DBInstanceIdentifier", local.db_instance_id_str, { stat = "Average", label = "CPU %" }],
            [".", "DatabaseConnections", ".", ".", { stat = "Average", yAxis = "right", label = "Connections" }]
          ]
          period = 300
          yAxis = {
            left  = { min = 0, max = 100, label = "CPU %" }
            right = { min = 0, label = "Connections" }
          }
        }
      },
      {
        type   = "metric"
        width  = 8
        height = 6
        x      = 16
        y      = 0
        properties = {
          title   = "ALB Target Health"
          region  = var.aws_region
          metrics = [
            ["AWS/ApplicationELB", "HealthyHostCount", "LoadBalancer", local.alb_arn_suffix_str, "TargetGroup", local.target_group_arn_suffix_str, { stat = "Average", label = "Healthy" }],
            [".", "UnHealthyHostCount", ".", ".", ".", ".", { stat = "Average", label = "Unhealthy", color = "#ff0000" }]
          ]
          period = 60
          stat   = "Average"
        }
      },
      {
        type   = "metric"
        width  = 24
        height = 6
        x      = 0
        y      = 6
        properties = {
          title   = "Active Alarms (Last Hour)"
          region  = var.aws_region
          metrics = [
            [{ expression = "SEARCH('{${local.project_name_str}/Alarms} MetricName', 'Sum', 300)", id = "alarms" }]
          ]
          period = 300
          stat   = "Sum"
          view   = "timeSeries"
          stacked = false
        }
      },
      {
        type   = "metric"
        width  = 12
        height = 6
        x      = 0
        y      = 12
        properties = {
          title   = "Network Traffic (VPC Flow Logs)"
          region  = var.aws_region
          metrics = [
            ["${local.project_name_str}/VPC", "RejectedConnections", { stat = "Sum", label = "Rejected", color = "#ff7f0e" }],
            [".", "SSHAttempts", { stat = "Sum", label = "SSH Attempts", color = "#d62728" }]
          ]
          period = 300
          stat   = "Sum"
          yAxis = {
            left = { min = 0 }
          }
        }
      },
      {
        type   = "metric"
        width  = 12
        height = 6
        x      = 12
        y      = 12
        properties = {
          title   = "Application Errors"
          region  = var.aws_region
          metrics = [
            ["AWS/ApplicationELB", "HTTPCode_Target_5XX_Count", "LoadBalancer", local.alb_arn_suffix_str, { stat = "Sum", label = "5XX Errors", color = "#d62728" }],
            [".", "HTTPCode_Target_4XX_Count", ".", ".", { stat = "Sum", label = "4XX Errors", color = "#ff7f0e" }]
          ]
          period = 300
          stat   = "Sum"
        }
      }
    ]
  })
}

# ----------------------------------------------------------------------------
# DASHBOARD 2: NETWORKING (VPC, VPN, ALB)
# ----------------------------------------------------------------------------
resource "aws_cloudwatch_dashboard" "networking" {
  dashboard_name = "${var.project_name}-networking"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "log"
        width  = 24
        height = 6
        x      = 0
        y      = 0
        properties = {
          title  = "VPC Flow Logs - Recent Rejected Connections"
          region = var.aws_region
          query  = <<-EOT
            SOURCE '/aws/vpc/${local.project_name_str}/flow-logs'
            | fields @timestamp, srcaddr, dstaddr, srcport, dstport, protocol, action
            | filter action = "REJECT"
            | sort @timestamp desc
            | limit 100
          EOT
        }
      },
      {
        type   = "metric"
        width  = 12
        height = 6
        x      = 0
        y      = 6
        properties = {
          title   = "Client VPN - Active Connections"
          region  = var.aws_region
          metrics = [
            ["AWS/ClientVPN", "ActiveConnectionsCount", "Endpoint", local.vpn_endpoint_id_str, { stat = "Average" }]
          ]
          period = 300
          stat   = "Average"
        }
      },
      {
        type   = "metric"
        width  = 12
        height = 6
        x      = 12
        y      = 6
        properties = {
          title   = "Client VPN - Authentication"
          region  = var.aws_region
          metrics = [
            ["AWS/ClientVPN", "AuthenticationFailures", "Endpoint", local.vpn_endpoint_id_str, { stat = "Sum", label = "Auth Failures", color = "#d62728" }],
            ["AWS/ClientVPN", "IngressBytes", "Endpoint", local.vpn_endpoint_id_str, { stat = "Sum", yAxis = "right", label = "Ingress" }],
            ["AWS/ClientVPN", "EgressBytes", "Endpoint", local.vpn_endpoint_id_str, { stat = "Sum", yAxis = "right", label = "Egress" }]
          ]
          period = 300
        }
      },
      {
        type   = "metric"
        width  = 12
        height = 6
        x      = 0
        y      = 12
        properties = {
          title   = "ALB - Request Count"
          region  = var.aws_region
          metrics = [
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", local.alb_arn_suffix_str, { stat = "Sum" }]
          ]
          period = 60
          stat   = "Sum"
        }
      },
      {
        type   = "metric"
        width  = 12
        height = 6
        x      = 12
        y      = 12
        properties = {
          title   = "ALB - Response Time"
          region  = var.aws_region
          metrics = [
            ["AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", local.alb_arn_suffix_str, { stat = "Average", label = "Avg Response Time (s)" }]
          ]
          period = 60
          stat   = "Average"
          yAxis = {
            left = { min = 0 }
          }
        }
      },
      {
        type   = "metric"
        width  = 24
        height = 6
        x      = 0
        y      = 18
        properties = {
          title   = "Network Firewall - Traffic & Drops"
          region  = var.aws_region
          metrics = [
            ["AWS/NetworkFirewall", "Packets", "FirewallName", local.firewall_name_str, { stat = "Sum", label = "Total Packets" }],
            [".", "DroppedPackets", ".", ".", { stat = "Sum", label = "Dropped", color = "#ff7f0e" }],
            [".", "InvalidPackets", ".", ".", { stat = "Sum", label = "Invalid", color = "#d62728" }]
          ]
          period = 300
          stat   = "Sum"
        }
      }
    ]
  })
}

# ----------------------------------------------------------------------------
# DASHBOARD 3: COMPUTE (EC2)
# ----------------------------------------------------------------------------
resource "aws_cloudwatch_dashboard" "compute" {
  dashboard_name = "${var.project_name}-compute"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        width  = 12
        height = 6
        x      = 0
        y      = 0
        properties = {
          title   = "EC2 - CPU Utilization"
          region  = var.aws_region
          metrics = [
            ["AWS/EC2", "CPUUtilization", "AutoScalingGroupName", local.asg_name_str, { stat = "Average" }]
          ]
          period = 300
          stat   = "Average"
          yAxis = {
            left = { min = 0, max = 100 }
          }
          annotations = {
            horizontal = [
              { value = 80, label = "Critical", color = "#d62728" },
              { value = 70, label = "Warning", color = "#ff7f0e" }
            ]
          }
        }
      },
      {
        type   = "metric"
        width  = 12
        height = 6
        x      = 12
        y      = 0
        properties = {
          title   = "EC2 - Memory Utilization"
          region  = var.aws_region
          metrics = [
            ["PCFactory/EC2", "MEMORY_USED", "AutoScalingGroupName", local.asg_name_str, { stat = "Average" }]
          ]
          period = 300
          stat   = "Average"
          yAxis = {
            left = { min = 0, max = 100 }
          }
          annotations = {
            horizontal = [
              { value = 85, label = "Critical", color = "#d62728" }
            ]
          }
        }
      },
      {
        type   = "metric"
        width  = 12
        height = 6
        x      = 0
        y      = 6
        properties = {
          title   = "EC2 - Disk Utilization"
          region  = var.aws_region
          metrics = [
            ["PCFactory/EC2", "DISK_USED", "AutoScalingGroupName", local.asg_name_str, { stat = "Average" }]
          ]
          period = 300
          stat   = "Average"
          yAxis = {
            left = { min = 0, max = 100 }
          }
        }
      },
      {
        type   = "metric"
        width  = 12
        height = 6
        x      = 12
        y      = 6
        properties = {
          title   = "EC2 - Network Traffic"
          region  = var.aws_region
          metrics = [
            ["AWS/EC2", "NetworkIn", "AutoScalingGroupName", local.asg_name_str, { stat = "Sum", label = "In" }],
            [".", "NetworkOut", ".", ".", { stat = "Sum", label = "Out" }]
          ]
          period = 300
          stat   = "Sum"
        }
      },
      {
        type   = "metric"
        width  = 12
        height = 6
        x      = 0
        y      = 12
        properties = {
          title   = "EC2 - Status Checks"
          region  = var.aws_region
          metrics = [
            ["AWS/EC2", "StatusCheckFailed_Instance", "AutoScalingGroupName", local.asg_name_str, { stat = "Maximum", label = "Instance Checks" }],
            [".", "StatusCheckFailed_System", ".", ".", { stat = "Maximum", label = "System Checks" }]
          ]
          period = 60
          stat   = "Maximum"
        }
      },
      {
        type   = "log"
        width  = 12
        height = 6
        x      = 12
        y      = 12
        properties = {
          title  = "Application Errors (Last Hour)"
          region = var.aws_region
          query  = <<-EOT
            SOURCE '/aws/ec2/${local.project_name_str}/application'
            | fields @timestamp, @message
            | filter @message like /ERROR/
            | sort @timestamp desc
            | limit 50
          EOT
        }
      }
    ]
  })
}

# ----------------------------------------------------------------------------
# DASHBOARD 4: DATABASE (RDS)
# ----------------------------------------------------------------------------
resource "aws_cloudwatch_dashboard" "database" {
  dashboard_name = "${var.project_name}-database"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        width  = 12
        height = 6
        x      = 0
        y      = 0
        properties = {
          title   = "RDS - CPU & Connections"
          region  = var.aws_region
          metrics = [
            ["AWS/RDS", "CPUUtilization", "DBInstanceIdentifier", local.db_instance_id_str, { stat = "Average", label = "CPU %", yAxis = "left" }],
            [".", "DatabaseConnections", ".", ".", { stat = "Average", label = "Connections", yAxis = "right" }]
          ]
          period = 300
          yAxis = {
            left  = { min = 0, max = 100 }
            right = { min = 0 }
          }
        }
      },
      {
        type   = "metric"
        width  = 12
        height = 6
        x      = 12
        y      = 0
        properties = {
          title   = "RDS - Memory"
          region  = var.aws_region
          metrics = [
            ["AWS/RDS", "FreeableMemory", "DBInstanceIdentifier", local.db_instance_id_str, { stat = "Average" }]
          ]
          period = 300
          stat   = "Average"
          yAxis = {
            left = { min = 0 }
          }
        }
      },
      {
        type   = "metric"
        width  = 12
        height = 6
        x      = 0
        y      = 6
        properties = {
          title   = "RDS - Read/Write Latency"
          region  = var.aws_region
          metrics = [
            ["AWS/RDS", "ReadLatency", "DBInstanceIdentifier", local.db_instance_id_str, { stat = "Average", label = "Read Latency" }],
            [".", "WriteLatency", ".", ".", { stat = "Average", label = "Write Latency" }]
          ]
          period = 300
          stat   = "Average"
          yAxis = {
            left = { min = 0 }
          }
        }
      },
      {
        type   = "metric"
        width  = 12
        height = 6
        x      = 12
        y      = 6
        properties = {
          title   = "RDS - IOPS"
          region  = var.aws_region
          metrics = [
            ["AWS/RDS", "ReadIOPS", "DBInstanceIdentifier", local.db_instance_id_str, { stat = "Average", label = "Read IOPS" }],
            [".", "WriteIOPS", ".", ".", { stat = "Average", label = "Write IOPS" }]
          ]
          period = 300
          stat   = "Average"
        }
      },
      {
        type   = "metric"
        width  = 12
        height = 6
        x      = 0
        y      = 12
        properties = {
          title   = "RDS - Storage Space"
          region  = var.aws_region
          metrics = [
            ["AWS/RDS", "FreeStorageSpace", "DBInstanceIdentifier", local.db_instance_id_str, { stat = "Average" }]
          ]
          period = 300
          stat   = "Average"
          yAxis = {
            left = { min = 0 }
          }
        }
      },
      {
        type   = "log"
        width  = 12
        height = 6
        x      = 12
        y      = 12
        properties = {
          title  = "RDS PostgreSQL Errors"
          region = var.aws_region
          query  = <<-EOT
            SOURCE '/aws/rds/instance/${local.db_instance_id_str}/postgresql'
            | fields @timestamp, @message
            | filter @message like /ERROR/
            | sort @timestamp desc
            | limit 50
          EOT
        }
      }
    ]
  })
}

# ----------------------------------------------------------------------------
# DASHBOARD 5: SECURITY
# ----------------------------------------------------------------------------
resource "aws_cloudwatch_dashboard" "security" {
  dashboard_name = "${var.project_name}-security"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        width  = 12
        height = 6
        x      = 0
        y      = 0
        properties = {
          title   = "VPN - Authentication Failures"
          region  = var.aws_region
          metrics = [
            ["AWS/ClientVPN", "AuthenticationFailures", "Endpoint", local.vpn_endpoint_id_str, { stat = "Sum" }]
          ]
          period = 300
          stat   = "Sum"
        }
      },
      {
        type   = "log"
        width  = 12
        height = 6
        x      = 12
        y      = 0
        properties = {
          title  = "Firewall - Critical Alerts"
          region = var.aws_region
          query  = <<-EOT
            SOURCE '/aws/networkfirewall/${local.project_name_str}/alert'
            | fields @timestamp, @message
            | filter @message like /ALERT/
            | sort @timestamp desc
            | limit 50
          EOT
        }
      },
      {
        type   = "metric"
        width  = 12
        height = 6
        x      = 0
        y      = 6
        properties = {
          title   = "VPC - Rejected Connections"
          region  = var.aws_region
          metrics = [
            ["${local.project_name_str}/VPC", "RejectedConnections", { stat = "Sum" }]
          ]
          period = 300
          stat   = "Sum"
        }
      },
      {
        type   = "metric"
        width  = 12
        height = 6
        x      = 12
        y      = 6
        properties = {
          title   = "Suspicious Connection Attempts"
          region  = var.aws_region
          metrics = [
            ["${local.project_name_str}/VPC", "SSHAttempts", { stat = "Sum", label = "SSH (Port 22)" }],
            ["${local.project_name_str}/VPC", "RDPAttempts", { stat = "Sum", label = "RDP (Port 3389)" }]
          ]
          period = 300
          stat   = "Sum"
        }
      },
      {
        type   = "log"
        width  = 24
        height = 6
        x      = 0
        y      = 12
        properties = {
          title  = "Security Events (Centralized)"
          region = var.aws_region
          query  = <<-EOT
            SOURCE '/aws/centralized/${local.project_name_str}/security'
            | fields @timestamp, @message
            | sort @timestamp desc
            | limit 100
          EOT
        }
      }
    ]
  })
}
