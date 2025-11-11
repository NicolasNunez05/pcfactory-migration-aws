# =============================================================================
# SYSTEMS MANAGER AUTOMATION
# =============================================================================
# Runbooks automatizados para operaciones comunes
# =============================================================================

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# =============================================================================
# IAM ROLE PARA AUTOMATION
# =============================================================================

resource "aws_iam_role" "automation" {
  name = "${var.project_name}-${var.environment}-ssm-automation"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ssm.amazonaws.com"
      }
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy" "automation_permissions" {
  name = "automation-permissions"
  role = aws_iam_role.automation.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:CreateSnapshot",
          "ec2:DeleteSnapshot",
          "ec2:DescribeSnapshots",
          "ec2:DescribeVolumes",
          "ec2:CreateTags",
          "rds:CreateDBSnapshot",
          "rds:DescribeDBSnapshots",
          "rds:DeleteDBSnapshot",
          "sns:Publish",
          "ssm:SendCommand",
          "ssm:GetCommandInvocation"
        ]
        Resource = "*"
      }
    ]
  })
}

# =============================================================================
# AUTOMATION DOCUMENT: EBS SNAPSHOT CREATION
# =============================================================================

resource "aws_ssm_document" "create_ebs_snapshot" {
  count = var.enable_snapshot_automation ? 1 : 0

  name            = "${var.project_name}-${var.environment}-create-ebs-snapshot"
  document_type   = "Automation"
  document_format = "YAML"

  content = yamlencode({
    schemaVersion = "0.3"
    description   = "Create EBS snapshots and delete old ones"
    assumeRole    = aws_iam_role.automation.arn
    
    parameters = {
      VolumeId = {
        type        = "String"
        description = "EBS Volume ID"
      }
      RetentionDays = {
        type        = "Integer"
        description = "Days to retain snapshots"
        default     = var.snapshot_retention_days
      }
    }

    mainSteps = [
      {
        name   = "createSnapshot"
        action = "aws:executeAwsApi"
        inputs = {
          Service = "ec2"
          Api     = "CreateSnapshot"
          VolumeId = "{{ VolumeId }}"
          Description = "Automated snapshot by SSM - ${var.project_name}"
          TagSpecifications = [{
            ResourceType = "snapshot"
            Tags = [{
              Key   = "CreatedBy"
              Value = "SSM-Automation"
            }, {
              Key   = "Project"
              Value = var.project_name
            }, {
              Key   = "Environment"
              Value = var.environment
            }]
          }]
        }
        outputs = [{
          Name     = "SnapshotId"
          Selector = "$.SnapshotId"
          Type     = "String"
        }]
      },
      {
        name   = "waitForSnapshot"
        action = "aws:waitForAwsResourceProperty"
        inputs = {
          Service      = "ec2"
          Api          = "DescribeSnapshots"
          SnapshotIds  = ["{{ createSnapshot.SnapshotId }}"]
          PropertySelector = "$.Snapshots[0].State"
          DesiredValues    = ["completed"]
        }
        timeoutSeconds = 3600
      },
      {
        name   = "notifySuccess"
        action = "aws:executeAwsApi"
        inputs = {
          Service = "sns"
          Api     = "Publish"
          TopicArn = var.sns_topic_arn
          Subject  = "EBS Snapshot Created"
          Message  = "Snapshot {{ createSnapshot.SnapshotId }} created successfully"
        }
      }
    ]
  })

  tags = var.tags
}

# =============================================================================
# AUTOMATION DOCUMENT: RDS SNAPSHOT CREATION
# =============================================================================

resource "aws_ssm_document" "create_rds_snapshot" {
  count = var.enable_backup_automation ? 1 : 0

  name            = "${var.project_name}-${var.environment}-create-rds-snapshot"
  document_type   = "Automation"
  document_format = "YAML"

  content = yamlencode({
    schemaVersion = "0.3"
    description   = "Create RDS snapshots automatically"
    assumeRole    = aws_iam_role.automation.arn
    
    parameters = {
      DBInstanceIdentifier = {
        type        = "String"
        description = "RDS Instance ID"
      }
    }

    mainSteps = [
      {
        name   = "createRDSSnapshot"
        action = "aws:executeAwsApi"
        inputs = {
          Service = "rds"
          Api     = "CreateDBSnapshot"
          DBInstanceIdentifier = "{{ DBInstanceIdentifier }}"
          DBSnapshotIdentifier = "${var.project_name}-{{ global:DATE_TIME }}"
          Tags = [{
            Key   = "CreatedBy"
            Value = "SSM-Automation"
          }]
        }
        outputs = [{
          Name     = "SnapshotId"
          Selector = "$.DBSnapshot.DBSnapshotIdentifier"
          Type     = "String"
        }]
      },
      {
        name   = "notifySuccess"
        action = "aws:executeAwsApi"
        inputs = {
          Service = "sns"
          Api     = "Publish"
          TopicArn = var.sns_topic_arn
          Subject  = "RDS Snapshot Created"
          Message  = "RDS Snapshot {{ createRDSSnapshot.SnapshotId }} created"
        }
      }
    ]
  })

  tags = var.tags
}

# =============================================================================
# AUTOMATION DOCUMENT: PATCH MANAGEMENT
# =============================================================================

resource "aws_ssm_document" "patch_instances" {
  count = var.enable_patching_automation ? 1 : 0

  name            = "${var.project_name}-${var.environment}-patch-instances"
  document_type   = "Automation"
  document_format = "YAML"

  content = yamlencode({
    schemaVersion = "0.3"
    description   = "Automated patch management for EC2 instances"
    assumeRole    = aws_iam_role.automation.arn
    
    parameters = {
      InstanceIds = {
        type        = "StringList"
        description = "EC2 Instance IDs to patch"
      }
    }

    mainSteps = [
      {
        name   = "scanForPatches"
        action = "aws:runCommand"
        inputs = {
          DocumentName = "AWS-RunPatchBaseline"
          InstanceIds  = "{{ InstanceIds }}"
          Parameters = {
            Operation = ["Scan"]
          }
        }
      },
      {
        name   = "installPatches"
        action = "aws:runCommand"
        inputs = {
          DocumentName = "AWS-RunPatchBaseline"
          InstanceIds  = "{{ InstanceIds }}"
          Parameters = {
            Operation = ["Install"]
            RebootOption = ["RebootIfNeeded"]
          }
        }
      },
      {
        name   = "notifyCompletion"
        action = "aws:executeAwsApi"
        inputs = {
          Service = "sns"
          Api     = "Publish"
          TopicArn = var.sns_topic_arn
          Subject  = "Patching Completed"
          Message  = "Patch installation completed for instances"
        }
      }
    ]
  })

  tags = var.tags
}

# =============================================================================
# EVENTBRIDGE RULES PARA AUTOMATIZACIÓN
# =============================================================================

# Rule: Snapshot diario de EBS
resource "aws_cloudwatch_event_rule" "ebs_snapshot_schedule" {
  count = var.enable_snapshot_automation ? 1 : 0

  name                = "${var.project_name}-ebs-snapshot-schedule"
  description         = "Trigger EBS snapshot automation"
  schedule_expression = var.backup_schedule

  tags = var.tags
}

resource "aws_cloudwatch_event_target" "ebs_snapshot" {
  count = var.enable_snapshot_automation ? 1 : 0

  rule     = aws_cloudwatch_event_rule.ebs_snapshot_schedule[0].name
  arn      = "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:automation-definition/${aws_ssm_document.create_ebs_snapshot[0].name}:$DEFAULT"
  role_arn = aws_iam_role.automation.arn

  input = jsonencode({
    VolumeId = "vol-xxxxx" # Placeholder - se debe configurar por instancia
  })
}

# Rule: Patching semanal
resource "aws_cloudwatch_event_rule" "patching_schedule" {
  count = var.enable_patching_automation ? 1 : 0

  name                = "${var.project_name}-patching-schedule"
  description         = "Trigger weekly patch automation"
  schedule_expression = var.patching_schedule

  tags = var.tags
}

resource "aws_cloudwatch_event_target" "patching" {
  count = var.enable_patching_automation ? 1 : 0

  rule     = aws_cloudwatch_event_rule.patching_schedule[0].name
  arn      = "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:automation-definition/${aws_ssm_document.patch_instances[0].name}:$DEFAULT"
  role_arn = aws_iam_role.automation.arn

  input = jsonencode({
    InstanceIds = ["i-xxxxx"] # Placeholder - configurar con instancias reales
  })
}

# IAM Role para EventBridge
resource "aws_iam_role" "eventbridge_ssm" {
  name = "${var.project_name}-${var.environment}-eventbridge-ssm"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "events.amazonaws.com"
      }
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy" "eventbridge_ssm" {
  name = "eventbridge-ssm-policy"
  role = aws_iam_role.eventbridge_ssm.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "ssm:StartAutomationExecution"
      ]
      Resource = "*"
    }]
  })
}
