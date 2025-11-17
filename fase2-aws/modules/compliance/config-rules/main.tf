locals {
  sns_arn = var.sns_topic_arn != null && var.sns_topic_arn != "" ? var.sns_topic_arn : "*"
}

# =============================================================================
# AWS CONFIG RULES
# =============================================================================
# Compliance continuo y auditoría de configuraciones
# =============================================================================

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# =============================================================================
# IAM ROLE PARA CONFIG
# =============================================================================

resource "aws_iam_role" "config" {
  name = "${var.project_name}-${var.environment}-config-role"

  force_detach_policies = true  

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "config.amazonaws.com"
      }
    }]
  })

  tags = var.tags
}

# Política IAM personalizada para AWS Config

resource "aws_iam_policy" "aws_config_custom_policy" {
  name        = "${var.project_name}-${var.environment}-aws-config-policy"
  description = "Política personalizada para AWS Config con permisos necesarios"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "config:*"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "s3:GetBucketAcl",
          "s3:PutObject",
          "s3:GetObject",
          "s3:ListBucket"
        ],
        Resource = [
          "arn:aws:s3:::${var.s3_bucket_name}",
          "arn:aws:s3:::${var.s3_bucket_name}/*"
        ]
      },
      {
        Effect = "Allow",
        Action = [
          "sns:Publish"
        ],
        Resource = local.sns_arn
      }
    ]
  })
}


# Adjuntar política personalizada al rol IAM
resource "aws_iam_role_policy_attachment" "config_custom_policy_attachment" {
  role       = aws_iam_role.config.name
  policy_arn = aws_iam_policy.aws_config_custom_policy.arn
}

# Inline policy para S3 (puedes eliminar si no la necesitas)
resource "aws_iam_role_policy" "config_s3" {
  name = "config-s3-policy"
  role = aws_iam_role.config.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "s3:GetBucketVersioning",
        "s3:PutObject",
        "s3:GetObject"
      ]
      Resource = [
        "arn:aws:s3:::${var.s3_bucket_name}",
        "arn:aws:s3:::${var.s3_bucket_name}/*"
      ]
    }]
  })
}

# =============================================================================
# CONFIG RECORDER
# =============================================================================

resource "aws_config_configuration_recorder" "main" {
  name     = "${var.project_name}-${var.environment}-recorder"
  role_arn = aws_iam_role.config.arn

  recording_group {
    all_supported                = var.enable_all_supported
    include_global_resource_types = true
  }
}

resource "aws_config_configuration_recorder_status" "main" {
  name       = aws_config_configuration_recorder.main.name
  is_enabled = true
  depends_on = [aws_config_delivery_channel.main]
}

# =============================================================================
# DELIVERY CHANNEL
# =============================================================================

resource "aws_config_delivery_channel" "main" {
  name           = "${var.project_name}-${var.environment}-delivery"
  s3_bucket_name = var.s3_bucket_name
  sns_topic_arn  = var.sns_topic_arn

  snapshot_delivery_properties {
    delivery_frequency = var.recording_frequency == "DAILY" ? "TwentyFour_Hours" : "Six_Hours"
  }

  depends_on = [aws_config_configuration_recorder.main]
}

# Política para bucket S3 usado para delivery de AWS Config
resource "aws_s3_bucket_policy" "config_logs" {
  bucket = var.s3_bucket_name

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
        Resource = "arn:aws:s3:::${var.s3_bucket_name}"
      },
      {
        Sid = "AWSConfigBucketPutObject",
        Effect = "Allow",
        Principal = {
          Service = "config.amazonaws.com"
        },
        Action = "s3:PutObject",
        Resource = "arn:aws:s3:::${var.s3_bucket_name}/*",
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      }
    ]
  })
}

# =============================================================================
# MANAGED CONFIG RULES
# =============================================================================

resource "aws_config_config_rule" "s3_encryption" {
  count = var.enable_managed_rules ? 1 : 0

  name = "${var.project_name}-s3-bucket-encryption"

  source {
    owner             = "AWS"
    source_identifier = "S3_BUCKET_SERVER_SIDE_ENCRYPTION_ENABLED"
  }

  depends_on = [aws_config_configuration_recorder.main]
}

resource "aws_config_config_rule" "rds_encryption" {
  count = var.enable_managed_rules ? 1 : 0

  name = "${var.project_name}-rds-storage-encrypted"

  source {
    owner             = "AWS"
    source_identifier = "RDS_STORAGE_ENCRYPTED"
  }

  depends_on = [aws_config_configuration_recorder.main]
}

resource "aws_config_config_rule" "ebs_encryption" {
  count = var.enable_managed_rules ? 1 : 0

  name = "${var.project_name}-ec2-ebs-encryption-by-default"

  source {
    owner             = "AWS"
    source_identifier = "EC2_EBS_ENCRYPTION_BY_DEFAULT"
  }

  depends_on = [aws_config_configuration_recorder.main]
}

resource "aws_config_config_rule" "sg_restricted" {
  count = var.enable_managed_rules ? 1 : 0

  name = "${var.project_name}-restricted-ssh"

  source {
    owner             = "AWS"
    source_identifier = "INCOMING_SSH_DISABLED"
  }

  depends_on = [aws_config_configuration_recorder.main]
}

resource "aws_config_config_rule" "cloudtrail_enabled" {
  count = var.enable_managed_rules ? 1 : 0

  name = "${var.project_name}-cloud-trail-enabled"

  source {
    owner             = "AWS"
    source_identifier = "CLOUD_TRAIL_ENABLED"
  }

  depends_on = [aws_config_configuration_recorder.main]
}

resource "aws_config_config_rule" "iam_password_policy" {
  count = var.enable_iam_password_policy ? 1 : 0

  name = "${var.project_name}-iam-password-policy"

  source {
    owner             = "AWS"
    source_identifier = "IAM_PASSWORD_POLICY"
  }

  input_parameters = jsonencode({
    RequireUppercaseCharacters = "true"
    RequireLowercaseCharacters = "true"
    RequireSymbols             = "true"
    RequireNumbers             = "true"
    MinimumPasswordLength      = "14"
    PasswordReusePrevention    = "24"
    MaxPasswordAge             = "90"
  })

  depends_on = [aws_config_configuration_recorder.main]
}

resource "aws_config_config_rule" "root_mfa" {
  count = var.enable_managed_rules ? 1 : 0

  name = "${var.project_name}-root-account-mfa-enabled"

  source {
    owner             = "AWS"
    source_identifier = "ROOT_ACCOUNT_MFA_ENABLED"
  }

  depends_on = [aws_config_configuration_recorder.main]
}

resource "aws_config_config_rule" "ec2_in_vpc" {
  count = var.enable_managed_rules ? 1 : 0

  name = "${var.project_name}-instances-in-vpc"

  source {
    owner             = "AWS"
    source_identifier = "INSTANCES_IN_VPC"
  }

  depends_on = [aws_config_configuration_recorder.main]
}

resource "aws_config_config_rule" "rds_backup" {
  count = var.enable_managed_rules ? 1 : 0

  name = "${var.project_name}-rds-deletion-protection-enabled"

  source {
    owner             = "AWS"
    source_identifier = "RDS_INSTANCE_DELETION_PROTECTION_ENABLED"
  }

  depends_on = [aws_config_configuration_recorder.main]
}

resource "aws_config_config_rule" "s3_versioning" {
  count = var.enable_managed_rules ? 1 : 0

  name = "${var.project_name}-s3-bucket-versioning-enabled"

  source {
    owner             = "AWS"
    source_identifier = "S3_BUCKET_VERSIONING_ENABLED"
  }

  depends_on = [aws_config_configuration_recorder.main]
}
