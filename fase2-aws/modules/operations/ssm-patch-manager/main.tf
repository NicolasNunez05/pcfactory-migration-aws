# =============================================================================
# KMS KEY PARA CIFRADO SSM
# =============================================================================
resource "aws_kms_key" "this" {
  description             = "KMS key para cifrado de logs y datos SSM Patch Manager - ${var.project_name}"
  deletion_window_in_days = 30
  enable_key_rotation     = true

  tags = {
    Name        = "${var.project_name}-${var.environment}-ssm-kms"
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# Alias para la clave KMS
resource "aws_kms_alias" "this" {
  name          = "alias/${var.project_name}-${var.environment}-ssm"
  target_key_id = aws_kms_key.this.key_id
}

# =============================================================================
# SSM DOCUMENT
# =============================================================================
resource "aws_ssm_document" "patch_baseline" {
  name          = "${var.project_name}-${var.environment}-patch-baseline"
  document_type = "Automation"
  content       = jsonencode(var.patch_document_content)
  tags = {
    Project     = var.project_name
    Environment = var.environment
  }
}

# =============================================================================
# SSM ASSOCIATION
# =============================================================================
# DESCOMENTAR DESPUÉS DEL PRIMER TERRAFORM APPLY
# resource "aws_ssm_association" "patch_association" {
#   count = length(var.instance_ids) > 0 ? length(var.instance_ids) : 0
#   
#   name = aws_ssm_document.patch_baseline.name
# 
#   targets {
#     key    = "InstanceIds"
#     values = [var.instance_ids[count.index]]
#   }
# 
#   schedule_expression = var.schedule_expression
#   compliance_severity = "CRITICAL"
# 
#   lifecycle {
#     ignore_changes = [parameters]
#   }
# }