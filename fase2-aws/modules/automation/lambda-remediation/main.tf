# =============================================================================
# LAMBDA AUTOMATED REMEDIATION
# =============================================================================
# Funciones Lambda para remediación automática de hallazgos
# =============================================================================

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# =============================================================================
# IAM ROLE PARA LAMBDA REMEDIATION
# =============================================================================

resource "aws_iam_role" "lambda_remediation" {
  name = "${var.project_name}-${var.environment}-lambda-remediation"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_remediation.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "remediation_permissions" {
  name = "remediation-permissions"
  role = aws_iam_role.lambda_remediation.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:RevokeSecurityGroupIngress",
          "ec2:DescribeSecurityGroups",
          "s3:PutBucketPublicAccessBlock",
          "s3:PutBucketVersioning",
          "s3:PutEncryptionConfiguration",
          "iam:DeleteAccessKey",
          "iam:UpdateAccessKey",
          "sns:Publish"
        ]
        Resource = "*"
      }
    ]
  })
}

# =============================================================================
# LAMBDA: SECURITY GROUP REMEDIATION
# =============================================================================

resource "aws_lambda_function" "sg_remediation" {
  count = var.enable_sg_remediation ? 1 : 0

  filename         = data.archive_file.sg_remediation[0].output_path
  function_name    = "${var.project_name}-${var.environment}-sg-remediation"
  role            = aws_iam_role.lambda_remediation.arn
  handler         = "index.lambda_handler"
  source_code_hash = data.archive_file.sg_remediation[0].output_base64sha256
  runtime         = "python3.11"
  timeout         = 60

  environment {
    variables = {
      SNS_TOPIC_ARN = var.sns_topic_arn
    }
  }

  tags = merge(
    {
      Name = "${var.project_name}-sg-remediation"
    },
    var.tags
  )
}

data "archive_file" "sg_remediation" {
  count = var.enable_sg_remediation ? 1 : 0

  type        = "zip"
  output_path = "${path.module}/sg_remediation.zip"

  source {
    content = <<-EOF
import json
import boto3
import os

ec2 = boto3.client('ec2')
sns = boto3.client('sns')

def lambda_handler(event, context):
    """
    Remueve reglas de security group que permiten 0.0.0.0/0 en puertos sensibles
    """
    print(f"Event: {json.dumps(event)}")
    
    # Extraer información del hallazgo
    finding = event['detail']['findings'][0]
    sg_id = finding['Resources'][0]['Id'].split('/')[-1]
    
    try:
        # Obtener reglas del security group
        response = ec2.describe_security_groups(GroupIds=[sg_id])
        sg = response['SecurityGroups'][0]
        
        remediated = False
        for rule in sg['IpPermissions']:
            # Puertos sensibles
            sensitive_ports = [22, 3389, 3306, 5432, 6379, 1433, 27017]
            
            for port in sensitive_ports:
                if rule.get('FromPort') == port or rule.get('ToPort') == port:
                    for ip_range in rule.get('IpRanges', []):
                        if ip_range.get('CidrIp') == '0.0.0.0/0':
                            # Revocar regla
                            ec2.revoke_security_group_ingress(
                                GroupId=sg_id,
                                IpPermissions=[rule]
                            )
                            remediated = True
                            print(f"Revoked rule for port {port} from 0.0.0.0/0")
        
        # Notificar
        if remediated:
            message = f"Security Group {sg_id} remediado: Reglas 0.0.0.0/0 eliminadas"
            sns.publish(
                TopicArn=os.environ['SNS_TOPIC_ARN'],
                Subject="Security Group Remediation",
                Message=message
            )
        
        return {
            'statusCode': 200,
            'body': json.dumps('Remediation completed')
        }
    
    except Exception as e:
        print(f"Error: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps(f'Error: {str(e)}')
        }
EOF
    filename = "index.py"
  }
}

# EventBridge rule para Security Hub findings
resource "aws_cloudwatch_event_rule" "sg_insecure" {
  count = var.enable_sg_remediation ? 1 : 0

  name        = "${var.project_name}-sg-insecure-rule"
  description = "Trigger Lambda for insecure Security Group findings"

  event_pattern = jsonencode({
    source      = ["aws.securityhub"]
    detail-type = ["Security Hub Findings - Imported"]
    detail = {
      findings = {
        Title = [{
          prefix = "Security group allows ingress from 0.0.0.0/0"
        }]
      }
    }
  })
}

resource "aws_cloudwatch_event_target" "sg_remediation" {
  count = var.enable_sg_remediation ? 1 : 0

  rule      = aws_cloudwatch_event_rule.sg_insecure[0].name
  target_id = "SGRemediationLambda"
  arn       = aws_lambda_function.sg_remediation[0].arn
}

resource "aws_lambda_permission" "allow_eventbridge_sg" {
  count = var.enable_sg_remediation ? 1 : 0

  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.sg_remediation[0].function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.sg_insecure[0].arn
}

# =============================================================================
# LAMBDA: S3 BUCKET REMEDIATION
# =============================================================================

resource "aws_lambda_function" "s3_remediation" {
  count = var.enable_s3_remediation ? 1 : 0

  filename         = data.archive_file.s3_remediation[0].output_path
  function_name    = "${var.project_name}-${var.environment}-s3-remediation"
  role            = aws_iam_role.lambda_remediation.arn
  handler         = "index.lambda_handler"
  source_code_hash = data.archive_file.s3_remediation[0].output_base64sha256
  runtime         = "python3.11"
  timeout         = 60

  environment {
    variables = {
      SNS_TOPIC_ARN = var.sns_topic_arn
    }
  }

  tags = merge(
    {
      Name = "${var.project_name}-s3-remediation"
    },
    var.tags
  )
}

data "archive_file" "s3_remediation" {
  count = var.enable_s3_remediation ? 1 : 0

  type        = "zip"
  output_path = "${path.module}/s3_remediation.zip"

  source {
    content = <<-EOF
import json
import boto3
import os

s3 = boto3.client('s3')
sns = boto3.client('sns')

def lambda_handler(event, context):
    """
    Habilita cifrado y bloquea acceso público en S3 buckets
    """
    print(f"Event: {json.dumps(event)}")
    
    finding = event['detail']['findings'][0]
    bucket_arn = finding['Resources'][0]['Id']
    bucket_name = bucket_arn.split(':')[-1]
    
    try:
        remediated_items = []
        
        # Habilitar cifrado
        try:
            s3.put_bucket_encryption(
                Bucket=bucket_name,
                ServerSideEncryptionConfiguration={
                    'Rules': [{
                        'ApplyServerSideEncryptionByDefault': {
                            'SSEAlgorithm': 'AES256'
                        }
                    }]
                }
            )
            remediated_items.append("Encryption enabled")
        except Exception as e:
            print(f"Encryption error: {e}")
        
        # Bloquear acceso público
        try:
            s3.put_public_access_block(
                Bucket=bucket_name,
                PublicAccessBlockConfiguration={
                    'BlockPublicAcls': True,
                    'IgnorePublicAcls': True,
                    'BlockPublicPolicy': True,
                    'RestrictPublicBuckets': True
                }
            )
            remediated_items.append("Public access blocked")
        except Exception as e:
            print(f"Public access error: {e}")
        
        # Habilitar versionado
        try:
            s3.put_bucket_versioning(
                Bucket=bucket_name,
                VersioningConfiguration={'Status': 'Enabled'}
            )
            remediated_items.append("Versioning enabled")
        except Exception as e:
            print(f"Versioning error: {e}")
        
        # Notificar
        if remediated_items:
            message = f"S3 Bucket {bucket_name} remediado:\n" + "\n".join(remediated_items)
            sns.publish(
                TopicArn=os.environ['SNS_TOPIC_ARN'],
                Subject="S3 Bucket Remediation",
                Message=message
            )
        
        return {
            'statusCode': 200,
            'body': json.dumps('Remediation completed')
        }
    
    except Exception as e:
        print(f"Error: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps(f'Error: {str(e)}')
        }
EOF
    filename = "index.py"
  }
}

# EventBridge rule para S3 findings
resource "aws_cloudwatch_event_rule" "s3_insecure" {
  count = var.enable_s3_remediation ? 1 : 0

  name        = "${var.project_name}-s3-insecure-rule"
  description = "Trigger Lambda for insecure S3 bucket findings"

  event_pattern = jsonencode({
    source      = ["aws.securityhub"]
    detail-type = ["Security Hub Findings - Imported"]
    detail = {
      findings = {
        Title = [{
          prefix = "S3 bucket"
        }]
        Compliance = {
          Status = ["FAILED"]
        }
      }
    }
  })
}

resource "aws_cloudwatch_event_target" "s3_remediation" {
  count = var.enable_s3_remediation ? 1 : 0

  rule      = aws_cloudwatch_event_rule.s3_insecure[0].name
  target_id = "S3RemediationLambda"
  arn       = aws_lambda_function.s3_remediation[0].arn
}

resource "aws_lambda_permission" "allow_eventbridge_s3" {
  count = var.enable_s3_remediation ? 1 : 0

  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.s3_remediation[0].function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.s3_insecure[0].arn
}
