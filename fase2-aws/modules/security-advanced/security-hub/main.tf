# =============================================================================
# AWS SECURITY HUB
# =============================================================================
# Dashboard consolidado de seguridad multi-servicio
# =============================================================================

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# =============================================================================
# SECURITY HUB
# =============================================================================

resource "aws_securityhub_account" "main" {
  control_finding_generator = var.control_finding_generator
  auto_enable_controls      = var.auto_enable_controls

  enable_default_standards = var.enable_default_standards
}

# =============================================================================
# SECURITY STANDARDS
# =============================================================================

# AWS Foundational Security Best Practices
resource "aws_securityhub_standards_subscription" "aws_foundational" {
  count           = var.enable_aws_foundational_security ? 1 : 0
  standards_arn   = "arn:aws:securityhub:${data.aws_region.current.name}::standards/aws-foundational-security-best-practices/v/1.0.0"
  depends_on      = [aws_securityhub_account.main]

  timeouts {
    create = "10m"  # ← AGREGAR ESTO
  }
}

# CIS AWS Foundations Benchmark v1.4
resource "aws_securityhub_standards_subscription" "cis_aws_v1_4" {
  count           = var.enable_cis_aws_foundations_v1_4 ? 1 : 0
  standards_arn   = "arn:aws:securityhub:${data.aws_region.current.name}::standards/cis-aws-foundations-benchmark/v/1.4.0"
  depends_on      = [aws_securityhub_account.main]

  timeouts {
    create = "10m"  # ← AGREGAR ESTO
  }
}

# PCI DSS v3.2.1
resource "aws_securityhub_standards_subscription" "pci_dss" {
  count = var.enable_pci_dss ? 1 : 0

  depends_on    = [aws_securityhub_account.main]
  standards_arn = "arn:aws:securityhub:${data.aws_region.current.name}::standards/pci-dss/v/3.2.1"
}

# NIST 800-53 Rev 5
resource "aws_securityhub_standards_subscription" "nist" {
  count = var.enable_nist ? 1 : 0

  depends_on    = [aws_securityhub_account.main]
  standards_arn = "arn:aws:securityhub:${data.aws_region.current.name}::standards/nist-800-53/v/5.0.0"
}

# =============================================================================
# PRODUCT INTEGRATIONS
# =============================================================================

# Integración con GuardDuty
resource "aws_securityhub_product_subscription" "guardduty" {
  depends_on  = [aws_securityhub_account.main]
  product_arn = "arn:aws:securityhub:${data.aws_region.current.name}::product/aws/guardduty"
}

# Integración con IAM Access Analyzer
resource "aws_securityhub_product_subscription" "iam_access_analyzer" {
  depends_on  = [aws_securityhub_account.main]
  product_arn = "arn:aws:securityhub:${data.aws_region.current.name}::product/aws/access-analyzer"
}

# Integración con Inspector (si está habilitado)
resource "aws_securityhub_product_subscription" "inspector" {
  depends_on  = [aws_securityhub_account.main]
  product_arn = "arn:aws:securityhub:${data.aws_region.current.name}::product/aws/inspector"
}

# =============================================================================
# EVENTBRIDGE RULE PARA FINDINGS
# =============================================================================

resource "aws_cloudwatch_event_rule" "security_hub_findings" {
  name        = "${var.project_name}-${var.environment}-securityhub-findings"
  description = "Capture Security Hub findings"

  event_pattern = jsonencode({
    source      = ["aws.securityhub"]
    detail-type = ["Security Hub Findings - Imported"]
    detail = {
      findings = {
        Severity = {
          Label = ["CRITICAL", "HIGH"]
        }
      }
    }
  })
}


