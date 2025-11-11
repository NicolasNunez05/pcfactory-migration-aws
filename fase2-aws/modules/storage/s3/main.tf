# =============================================================================
# MÓDULO S3 STORAGE - CONFIGURACIÓN PROFESIONAL
# =============================================================================
# Buckets S3 con versionado, lifecycle policies, cifrado KMS y logging
# Proyecto: PCFactory Migration AWS - Capstone DuocUC 2025
# Autor: Nicolás Núñez Álvarez
# Última actualización: 09 de noviembre de 2025
# =============================================================================

# Data sources
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# =============================================================================
# BUCKET 1: BACKUPS (EC2, RDS, Snapshots)
# =============================================================================

resource "aws_s3_bucket" "backups" {
  count = var.enable_backups_bucket ? 1 : 0

  bucket = "${var.project_name}-backups-${var.environment}"

  tags = merge(
    {
      Name        = "${var.project_name}-backups-${var.environment}"
      Environment = var.environment
      Project     = var.project_name
      Purpose     = "EC2/RDS Backups and Snapshots"
      ManagedBy   = "Terraform"
    },
    var.tags
  )
}

# Versionado habilitado para backups
resource "aws_s3_bucket_versioning" "backups" {
  count = var.enable_backups_bucket ? 1 : 0

  bucket = aws_s3_bucket.backups[0].id

  versioning_configuration {
    status     = "Enabled"
    mfa_delete = var.enable_mfa_delete ? "Enabled" : "Disabled"
  }
}

# Cifrado con KMS para backups
resource "aws_s3_bucket_server_side_encryption_configuration" "backups" {
  count = var.enable_backups_bucket ? 1 : 0

  bucket = aws_s3_bucket.backups[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = var.kms_key_id
    }
    bucket_key_enabled = true
  }
}

# Block Public Access para backups
resource "aws_s3_bucket_public_access_block" "backups" {
  count = var.enable_backups_bucket ? 1 : 0

  bucket = aws_s3_bucket.backups[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Lifecycle Policy para backups
resource "aws_s3_bucket_lifecycle_configuration" "backups" {
  count = var.enable_backups_bucket ? 1 : 0

  bucket = aws_s3_bucket.backups[0].id

  rule {
    id     = "backups-lifecycle-rule"
    status = "Enabled"

    # Transición a STANDARD_IA
    transition {
      days          = var.backups_standard_days
      storage_class = "STANDARD_IA"
    }

    # Transición a GLACIER_IR
    transition {
      days          = var.backups_ia_days
      storage_class = "GLACIER_IR"
    }

    # Transición a DEEP_ARCHIVE
    transition {
      days          = var.backups_glacier_days
      storage_class = "DEEP_ARCHIVE"
    }

    # Eliminar versiones no actuales después de 90 días
    noncurrent_version_transition {
      noncurrent_days = 30
      storage_class   = "STANDARD_IA"
    }

    noncurrent_version_transition {
      noncurrent_days = 60
      storage_class   = "GLACIER_IR"
    }

    noncurrent_version_expiration {
      noncurrent_days = var.backups_noncurrent_version_days
    }

    # Eliminar marcadores de eliminación huérfanos
    expiration {
      expired_object_delete_marker = true
    }

    # Limpiar uploads multiparte incompletos
    abort_incomplete_multipart_upload {
      days_after_initiation = var.incomplete_multipart_days
    }
  }
}

# Logging de acceso para backups
resource "aws_s3_bucket_logging" "backups" {
  count = var.enable_backups_bucket && var.enable_access_logging && var.enable_logs_bucket ? 1 : 0

  bucket = aws_s3_bucket.backups[0].id

  target_bucket = aws_s3_bucket.logs[0].id
  target_prefix = "s3-access-logs/backups/"
}

# =============================================================================
# BUCKET 2: LOGS (CloudWatch, VPC Flow Logs, Access Logs)
# =============================================================================

resource "aws_s3_bucket" "logs" {
  count = var.enable_logs_bucket ? 1 : 0

  bucket = "${var.project_name}-logs-${var.environment}"

  tags = merge(
    {
      Name        = "${var.project_name}-logs-${var.environment}"
      Environment = var.environment
      Project     = var.project_name
      Purpose     = "Application and Infrastructure Logs"
      ManagedBy   = "Terraform"
    },
    var.tags
  )
}

# Sin versionado para logs (no necesario)
resource "aws_s3_bucket_versioning" "logs" {
  count = var.enable_logs_bucket ? 1 : 0

  bucket = aws_s3_bucket.logs[0].id

  versioning_configuration {
    status = "Disabled"
  }
}

# Cifrado con KMS para logs
resource "aws_s3_bucket_server_side_encryption_configuration" "logs" {
  count = var.enable_logs_bucket ? 1 : 0

  bucket = aws_s3_bucket.logs[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = var.kms_key_id
    }
    bucket_key_enabled = true
  }
}

# Block Public Access para logs
resource "aws_s3_bucket_public_access_block" "logs" {
  count = var.enable_logs_bucket ? 1 : 0

  bucket = aws_s3_bucket.logs[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Lifecycle Policy para logs
resource "aws_s3_bucket_lifecycle_configuration" "logs" {
  count = var.enable_logs_bucket ? 1 : 0

  bucket = aws_s3_bucket.logs[0].id

  rule {
    id     = "logs-lifecycle-rule"
    status = "Enabled"

    # Transición a STANDARD_IA
    transition {
      days          = var.logs_standard_days
      storage_class = "STANDARD_IA"
    }

    # Eliminar logs después de 90 días
    expiration {
      days = var.logs_expiration_days
    }

    # Limpiar uploads multiparte incompletos
    abort_incomplete_multipart_upload {
      days_after_initiation = var.incomplete_multipart_days
    }
  }
}

# Política del bucket para permitir S3 Access Logs
resource "aws_s3_bucket_policy" "logs" {
  count = var.enable_logs_bucket ? 1 : 0

  bucket = aws_s3_bucket.logs[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "S3ServerAccessLogsPolicy"
        Effect = "Allow"
        Principal = {
          Service = "logging.s3.amazonaws.com"
        }
        Action = [
          "s3:PutObject"
        ]
        Resource = "${aws_s3_bucket.logs[0].arn}/s3-access-logs/*"
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }
        }
      }
    ]
  })
}

# =============================================================================
# BUCKET 3: ARTIFACTS (CI/CD, Builds, Releases)
# =============================================================================

resource "aws_s3_bucket" "artifacts" {
  count = var.enable_artifacts_bucket ? 1 : 0

  bucket = "${var.project_name}-artifacts-${var.environment}"

  tags = merge(
    {
      Name        = "${var.project_name}-artifacts-${var.environment}"
      Environment = var.environment
      Project     = var.project_name
      Purpose     = "CI/CD Artifacts and Releases"
      ManagedBy   = "Terraform"
    },
    var.tags
  )
}

# Versionado habilitado para artifacts
resource "aws_s3_bucket_versioning" "artifacts" {
  count = var.enable_artifacts_bucket ? 1 : 0

  bucket = aws_s3_bucket.artifacts[0].id

  versioning_configuration {
    status = "Enabled"
  }
}

# Cifrado con KMS para artifacts
resource "aws_s3_bucket_server_side_encryption_configuration" "artifacts" {
  count = var.enable_artifacts_bucket ? 1 : 0

  bucket = aws_s3_bucket.artifacts[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = var.kms_key_id
    }
    bucket_key_enabled = true
  }
}

# Block Public Access para artifacts
resource "aws_s3_bucket_public_access_block" "artifacts" {
  count = var.enable_artifacts_bucket ? 1 : 0

  bucket = aws_s3_bucket.artifacts[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Lifecycle Policy para artifacts
resource "aws_s3_bucket_lifecycle_configuration" "artifacts" {
  count = var.enable_artifacts_bucket ? 1 : 0

  bucket = aws_s3_bucket.artifacts[0].id

  rule {
    id     = "artifacts-lifecycle-rule"
    status = "Enabled"

    transition {
      days          = var.artifacts_standard_days
      storage_class = "STANDARD_IA"
    }

    # Eliminar objetos después de X días
    expiration {
      days = var.artifacts_ia_days
    }

    noncurrent_version_transition {
      noncurrent_days = 30
      storage_class   = "STANDARD_IA"
    }

    noncurrent_version_expiration {
      noncurrent_days = var.artifacts_noncurrent_version_days
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = var.incomplete_multipart_days
    }
  }

  # Regla separada para eliminar marcadores de eliminación expirados
  rule {
    id     = "delete-expired-markers"
    status = "Enabled"

    expiration {
      expired_object_delete_marker = true
    }
  }

  lifecycle {
    ignore_changes = [
      rule
    ]
  }
}


# Logging de acceso para artifacts
resource "aws_s3_bucket_logging" "artifacts" {
  count = var.enable_artifacts_bucket && var.enable_access_logging && var.enable_logs_bucket ? 1 : 0

  bucket = aws_s3_bucket.artifacts[0].id

  target_bucket = aws_s3_bucket.logs[0].id
  target_prefix = "s3-access-logs/artifacts/"
}

resource "aws_s3_bucket_policy" "config_logs" {
  bucket = aws_s3_bucket.logs[0].id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid = "AWSConfigBucketPermissionsCheck",
        Effect = "Allow",
        Principal = {
          Service = "config.amazonaws.com"
        },
        Action = [
          "s3:GetBucketAcl",
          "s3:ListBucket"
        ],
        Resource = aws_s3_bucket.logs[0].arn
      },
      {
        Sid = "AWSConfigBucketPutObject",
        Effect = "Allow",
        Principal = {
          Service = "config.amazonaws.com"
        },
        Action = "s3:PutObject",
        Resource = "${aws_s3_bucket.logs[0].arn}/*",
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      }
    ]
  })
}