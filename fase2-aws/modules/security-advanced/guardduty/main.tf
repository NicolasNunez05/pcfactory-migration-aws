# =============================================================================
# GUARDDUTY CON S3 PROTECTION
# =============================================================================
# Detección inteligente de amenazas con protección avanzada
# Última actualización: 09 de noviembre de 2025
# =============================================================================

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# =============================================================================
# GUARDDUTY DETECTOR
# =============================================================================

resource "aws_guardduty_detector" "main" {
  enable                       = true
  finding_publishing_frequency = var.finding_publishing_frequency

  datasources {
    s3_logs {
      enable = var.enable_s3_protection
    }

    kubernetes {
      audit_logs {
        enable = var.enable_kubernetes_protection
      }
    }

    malware_protection {
      scan_ec2_instance_with_findings {
        ebs_volumes {
          enable = var.enable_malware_protection
        }
      }
    }
  }

  tags = merge(
    {
      Name        = "${var.project_name}-${var.environment}-guardduty"
      Environment = var.environment
      Project     = var.project_name
      ManagedBy   = "Terraform"
    },
    var.tags
  )
}

# =============================================================================
# GUARDDUTY PUBLISHING DESTINATION (EventBridge)
# =============================================================================

resource "aws_cloudwatch_event_rule" "guardduty_findings" {
  name        = "${var.project_name}-${var.environment}-guardduty-findings"
  description = "Captura los hallazgos de GuardDuty y los envía a SNS"
  event_pattern = jsonencode({
    "source" : ["aws.guardduty"]
  })

  tags = merge(
    {
      Name = "${var.project_name}-${var.environment}-guardduty-rule"
    },
    var.tags
  )
}

# Target para SNS si se proporciona
resource "aws_cloudwatch_event_target" "sns" {
  rule      = aws_cloudwatch_event_rule.guardduty_findings.name
  target_id = "SendToSNS"
  arn       = var.sns_topic_arn
}

# =============================================================================
# THREAT INTEL SETS (Listas de IPs maliciosas conocidas)
# =============================================================================
# COMENTADO TEMPORALMENTE - Requiere permisos adicionales de IAM

# resource "aws_guardduty_threatintelset" "example" {
#   activate    = true
#   detector_id = aws_guardduty_detector.main.id
#   format      = "TXT"
#   location    = "https://s3.amazonaws.com/${var.project_name}-threat-intel/malicious-ips.txt"
#   name        = "${var.project_name}-threat-intel-set"
#
#   tags = merge(
#     {
#       Name = "${var.project_name}-threat-intel"
#     },
#     var.tags
#   )
#
#   lifecycle {
#     ignore_changes = [location]
#   }
# }

# =============================================================================
# IP SETS (Lista blanca de IPs confiables - opcional)
# =============================================================================
# COMENTADO TEMPORALMENTE - Requiere permisos adicionales de IAM

# resource "aws_guardduty_ipset" "trusted" {
#   activate    = true
#   detector_id = aws_guardduty_detector.main.id
#   format      = "TXT"
#   location    = "https://s3.amazonaws.com/${var.project_name}-threat-intel/trusted-ips.txt"
#   name        = "${var.project_name}-trusted-ipset"
#
#   tags = merge(
#     {
#       Name = "${var.project_name}-trusted-ips"
#     },
#     var.tags
#   )
#
#   lifecycle {
#     ignore_changes = [location]
#   }
# }

# =============================================================================
# IAM ROLE para GuardDuty con permisos necesarios
# =============================================================================

resource "aws_iam_role" "guardduty_role" {
  name = "${var.project_name}-${var.environment}-guardduty-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "guardduty.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = merge(
    {
      Name        = "${var.project_name}-${var.environment}-guardduty-role"
      Environment = var.environment
      Project     = var.project_name
      ManagedBy   = "Terraform"
    },
    var.tags
  )
}

resource "aws_iam_policy" "guardduty_extra_permissions" {
  name        = "${var.project_name}-${var.environment}-guardduty-extra-permissions"
  description = "Permisos GuardDuty adicionales para creación de ThreatIntelSet e IPSet"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = [
          "guardduty:CreateThreatIntelSet",
          "guardduty:UpdateThreatIntelSet",
          "guardduty:GetThreatIntelSet",
          "guardduty:DeleteThreatIntelSet",
          "guardduty:CreateIPSet",
          "guardduty:UpdateIPSet",
          "guardduty:GetIPSet",
          "guardduty:DeleteIPSet"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_guardduty_permissions" {
  role       = aws_iam_role.guardduty_role.name
  policy_arn = aws_iam_policy.guardduty_extra_permissions.arn
}
