data "aws_caller_identity" "current" {}

# S3 Bucket para backups
resource "aws_s3_bucket" "rds_backups" {
  bucket = "${var.project_name}-rds-backups-${data.aws_caller_identity.current.account_id}"
  
  tags = {
    Name        = "${var.project_name}-rds-backups"
    Environment = var.environment
  }
}

# Block public access
resource "aws_s3_bucket_public_access_block" "rds_backups" {
  bucket = aws_s3_bucket.rds_backups.id
  
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Enable versioning
resource "aws_s3_bucket_versioning" "rds_backups" {
  bucket = aws_s3_bucket.rds_backups.id
  
  versioning_configuration {
    status = "Enabled"
  }
}

# AWS Backup - Plan diario
resource "aws_backup_vault" "rds" {
  name = "${var.project_name}-backup-vault"
  
  tags = {
    Environment = var.environment
  }
}

resource "aws_backup_plan" "rds" {
  name = "${var.project_name}-rds-backup-plan"
  
  rule {
    rule_name         = "daily_backup"
    target_vault_name = aws_backup_vault.rds.name
    schedule          = "cron(0 5 * * ? *)"  # 5 AM UTC daily
    start_window      = 60
    completion_window = 120
    
    lifecycle {
      delete_after       = 30  # Keep for 30 days
      cold_storage_after = 7   # Move to Glacier after 7 days
    }
  }
}

# IAM Role para AWS Backup
resource "aws_iam_role" "backup" {
  name = "${var.project_name}-backup-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "backup.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "backup" {
  role       = aws_iam_role.backup.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
}

# Backup resource assignment
resource "aws_backup_selection" "rds" {
  name            = "${var.project_name}-rds-backup-selection"
  plan_id         = aws_backup_plan.rds.id
  iam_role_arn    = aws_iam_role.backup.arn
  
  selection_tag {
    type   = "STRINGEQUALS"
    key    = "Backup"
    value  = "true"
  }
}


# Outputs
output "backup_vault_arn" {
  value = aws_backup_vault.rds.arn
}

output "s3_backups_bucket" {
  value = aws_s3_bucket.rds_backups.id
}
