# ============================================================================
# LAMBDA FUNCTION - RDS SNAPSHOT MANAGER
# ============================================================================

data "archive_file" "lambda_snapshot_manager" {
  type        = "zip"
  source_dir  = "${path.module}/function"
  output_path = "${path.module}/lambda_snapshot_manager.zip"
}

# ----------------------------------------------------------------------------
# IAM ROLE
# ----------------------------------------------------------------------------
resource "aws_iam_role" "lambda_snapshot_manager" {
  name = "${var.project_name}-lambda-snapshot-manager-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-lambda-snapshot-manager-role"
  }
}

# Policy básica para logs
resource "aws_iam_role_policy_attachment" "lambda_snapshot_manager_logs" {
  role       = aws_iam_role.lambda_snapshot_manager.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Policy custom para RDS snapshots
resource "aws_iam_policy" "lambda_snapshot_manager_rds" {
  name = "${var.project_name}-lambda-snapshot-manager-rds"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "rds:DescribeDBInstances",
          "rds:DescribeDBSnapshots",
          "rds:CreateDBSnapshot",
          "rds:DeleteDBSnapshot",
          "rds:AddTagsToResource",
          "rds:ListTagsForResource",
          "sns:Publish"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_snapshot_manager_rds" {
  role       = aws_iam_role.lambda_snapshot_manager.name
  policy_arn = aws_iam_policy.lambda_snapshot_manager_rds.arn
}

# ----------------------------------------------------------------------------
# LAMBDA FUNCTION
# ----------------------------------------------------------------------------
resource "aws_lambda_function" "snapshot_manager" {
  filename         = data.archive_file.lambda_snapshot_manager.output_path
  function_name    = "${var.project_name}-snapshot-manager"
  role             = aws_iam_role.lambda_snapshot_manager.arn
  handler          = "lambda_function.lambda_handler"
  source_code_hash = data.archive_file.lambda_snapshot_manager.output_base64sha256
  runtime          = "python3.11"
  timeout          = 300  # 5 minutos
  memory_size      = 256

  environment {
    variables = {
      PROJECT_NAME            = var.project_name
      NOTIFICATION_TOPIC_ARN  = var.notification_topic_arn
      RETENTION_DAYS          = var.retention_days
    }
  }

  tags = {
    Name        = "${var.project_name}-snapshot-manager"
    Environment = var.environment
  }
}

# ----------------------------------------------------------------------------
# EVENTBRIDGE RULE - Programar ejecución
# ----------------------------------------------------------------------------
resource "aws_cloudwatch_event_rule" "snapshot_schedule" {
  name                = "${var.project_name}-snapshot-schedule"
  description         = "Ejecuta Lambda de snapshots según schedule"
  schedule_expression = var.schedule_expression  # Ej: "cron(0 2 * * ? *)" = 2 AM diario

  tags = {
    Name = "${var.project_name}-snapshot-schedule"
  }
}

resource "aws_cloudwatch_event_target" "lambda_snapshot_manager" {
  rule      = aws_cloudwatch_event_rule.snapshot_schedule.name
  target_id = "LambdaSnapshotManager"
  arn       = aws_lambda_function.snapshot_manager.arn
}

resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.snapshot_manager.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.snapshot_schedule.arn
}

# ----------------------------------------------------------------------------
# CLOUDWATCH ALARMS para la Lambda
# ----------------------------------------------------------------------------
resource "aws_cloudwatch_metric_alarm" "lambda_snapshot_errors" {
  alarm_name          = "${var.project_name}-lambda-snapshot-manager-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Sum"
  threshold           = 0
  alarm_description   = "Lambda snapshot manager tiene errores"
  alarm_actions       = [var.sns_topic_critical_arn]

  dimensions = {
    FunctionName = aws_lambda_function.snapshot_manager.function_name
  }

  tags = {
    Name     = "${var.project_name}-lambda-snapshot-errors"
    Severity = "Critical"
  }
}
