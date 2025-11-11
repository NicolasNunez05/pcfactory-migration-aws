# ============================================================================
# LAMBDA FUNCTION - ALARM RESPONDER (AUTO-REMEDIATION)
# ============================================================================

data "archive_file" "lambda_alarm_responder" {
  type        = "zip"
  source_dir  = "${path.module}/function"
  output_path = "${path.module}/lambda_alarm_responder.zip"
}

# ----------------------------------------------------------------------------
# IAM ROLE
# ----------------------------------------------------------------------------
resource "aws_iam_role" "lambda_alarm_responder" {
  name = "${var.project_name}-lambda-alarm-responder-role"

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
}

# Policy básica para logs
resource "aws_iam_role_policy_attachment" "lambda_alarm_responder_logs" {
  role       = aws_iam_role.lambda_alarm_responder.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Policy custom para remediación
resource "aws_iam_policy" "lambda_alarm_responder_remediation" {
  name = "${var.project_name}-lambda-alarm-responder-remediation"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:RebootInstances",
          "ec2:DescribeInstances",
          "autoscaling:DescribeAutoScalingGroups",
          "autoscaling:SetDesiredCapacity",
          "rds:DescribeDBInstances",
          "rds:ModifyDBInstance",
          "sns:Publish",
          "cloudwatch:DescribeAlarms"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_alarm_responder_remediation" {
  role       = aws_iam_role.lambda_alarm_responder.name
  policy_arn = aws_iam_policy.lambda_alarm_responder_remediation.arn
}

# ----------------------------------------------------------------------------
# LAMBDA FUNCTION
# ----------------------------------------------------------------------------
resource "aws_lambda_function" "alarm_responder" {
  filename         = data.archive_file.lambda_alarm_responder.output_path
  function_name    = "${var.project_name}-alarm-responder"
  role             = aws_iam_role.lambda_alarm_responder.arn
  handler          = "lambda_function.lambda_handler"
  source_code_hash = data.archive_file.lambda_alarm_responder.output_base64sha256
  runtime          = "python3.11"
  timeout          = 300  # 5 minutos
  memory_size      = 256

  environment {
    variables = {
      PROJECT_NAME            = var.project_name
      NOTIFICATION_TOPIC_ARN  = var.notification_topic_arn
    }
  }

  tags = {
    Name        = "${var.project_name}-alarm-responder"
    Environment = var.environment
  }
}

# ----------------------------------------------------------------------------
# SNS SUBSCRIPTION (Lambda se subscribe al topic de alarmas críticas)
# ----------------------------------------------------------------------------
resource "aws_sns_topic_subscription" "alarm_responder" {
  topic_arn = var.alarm_topic_arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.alarm_responder.arn
}

resource "aws_lambda_permission" "allow_sns" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.alarm_responder.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = var.alarm_topic_arn
}
