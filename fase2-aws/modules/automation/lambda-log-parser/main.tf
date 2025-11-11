# ============================================================================
# LAMBDA FUNCTION - LOG PARSER
# ============================================================================
# Parsea logs de CloudWatch y extrae métricas custom

# ----------------------------------------------------------------------------
# DATA: Empaquetar código Python
# ----------------------------------------------------------------------------
data "archive_file" "lambda_log_parser" {
  type        = "zip"
  source_dir  = "${path.module}/function"
  output_path = "${path.module}/lambda_log_parser.zip"
}

# ----------------------------------------------------------------------------
# IAM ROLE para Lambda
# ----------------------------------------------------------------------------
resource "aws_iam_role" "lambda_log_parser" {
  name = "${var.project_name}-lambda-log-parser-role"

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
    Name = "${var.project_name}-lambda-log-parser-role"
  }
}

# Policy para escribir logs
resource "aws_iam_role_policy_attachment" "lambda_log_parser_logs" {
  role       = aws_iam_role.lambda_log_parser.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Policy custom para CloudWatch Metrics
resource "aws_iam_policy" "lambda_log_parser_cloudwatch" {
  name = "${var.project_name}-lambda-log-parser-cloudwatch"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:PutMetricData"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_log_parser_cloudwatch" {
  role       = aws_iam_role.lambda_log_parser.name
  policy_arn = aws_iam_policy.lambda_log_parser_cloudwatch.arn
}

# ----------------------------------------------------------------------------
# LAMBDA FUNCTION
# ----------------------------------------------------------------------------
resource "aws_lambda_function" "log_parser" {
  filename         = data.archive_file.lambda_log_parser.output_path
  function_name    = "${var.project_name}-log-parser"
  role             = aws_iam_role.lambda_log_parser.arn
  handler          = "lambda_function.lambda_handler"
  source_code_hash = data.archive_file.lambda_log_parser.output_base64sha256
  runtime          = "python3.11"
  timeout          = 60
  memory_size      = 256

  environment {
    variables = {
      PROJECT_NAME        = var.project_name
      CLOUDWATCH_NAMESPACE = "${var.project_name}/Custom"
    }
  }

  tags = {
    Name        = "${var.project_name}-log-parser"
    Environment = var.environment
  }
}

# ----------------------------------------------------------------------------
# CLOUDWATCH LOGS PERMISSION (para que CloudWatch pueda invocar Lambda)
# ----------------------------------------------------------------------------
resource "aws_lambda_permission" "allow_cloudwatch_logs" {
  statement_id  = "AllowExecutionFromCloudWatchLogs"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.log_parser.function_name
  principal     = "logs.amazonaws.com"
  source_arn    = "${var.source_log_group_arn}:*"
}

# ----------------------------------------------------------------------------
# SUBSCRIPTION FILTER (conecta CloudWatch Logs con Lambda)
# ----------------------------------------------------------------------------
resource "aws_cloudwatch_log_subscription_filter" "log_parser" {
  name            = "${var.project_name}-log-parser-subscription"
  log_group_name  = var.source_log_group_name
  filter_pattern  = var.filter_pattern
  destination_arn = aws_lambda_function.log_parser.arn

  depends_on = [aws_lambda_permission.allow_cloudwatch_logs]
}

# ----------------------------------------------------------------------------
# CLOUDWATCH ALARMS para la Lambda
# ----------------------------------------------------------------------------
resource "aws_cloudwatch_metric_alarm" "lambda_errors" {
  alarm_name          = "${var.project_name}-lambda-log-parser-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Sum"
  threshold           = 5
  alarm_description   = "Lambda log parser tiene errores"
  alarm_actions       = [var.sns_topic_warning_arn]

  dimensions = {
    FunctionName = aws_lambda_function.log_parser.function_name
  }
}
