# ============================================================================
# IAM POLICIES PARA CLOUDWATCH LOGS
# ============================================================================

# ----------------------------------------------------------------------------
# Policy para que EC2 escriba logs
# ----------------------------------------------------------------------------
data "aws_iam_policy_document" "ec2_logs" {
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogStreams"
    ]
    resources = [
      "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/ec2/*",
      "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/centralized/*"
    ]
  }
}

resource "aws_iam_policy" "ec2_logs" {
  name        = "${var.project_name}-ec2-cloudwatch-logs"
  description = "Permite a instancias EC2 escribir logs a CloudWatch"
  policy      = data.aws_iam_policy_document.ec2_logs.json
}

# Output para adjuntar al role de EC2
output "ec2_logs_policy_arn" {
  description = "ARN de la policy para EC2 logs"
  value       = aws_iam_policy.ec2_logs.arn
}
