# ========================================
# IAM ROLE PARA EC2
# ========================================

# Data source para obtener región actual
data "aws_region" "current" {}

# El bloque de data sources para el ASG y las instancias fue eliminado
# porque creaba una dependencia circular y no se utilizaba.

resource "aws_iam_role" "ec2_app_role" {
  name = "${var.project_name}-ec2-app-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-ec2-app-role"
  }
}

# Adjuntar políticas necesarias
resource "aws_iam_role_policy_attachment" "ssm_policy" {
  role       = aws_iam_role.ec2_app_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "ssm_patch_manager" {
  role       = aws_iam_role.ec2_app_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMPatchAssociation" # No existe esta policy, probablemente es AmazonSSMManagedInstanceCore o una custom. Revisar nombre.
}

resource "aws_iam_role_policy_attachment" "cloudwatch_policy" {
  role       = aws_iam_role.ec2_app_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# Policy adicional para CloudWatch Logs
resource "aws_iam_policy" "cloudwatch_logs_custom" {
  name        = "${var.project_name}-ec2-cloudwatch-logs-custom"
  description = "Permisos adicionales para escribir logs a CloudWatch desde EC2"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams",
          "logs:DescribeLogGroups"
        ]
        Resource = [
          "arn:aws:logs:*:*:log-group:/aws/ec2/${var.project_name}/*",
          "arn:aws:logs:*:*:log-group:/aws/centralized/${var.project_name}/*"
        ]
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-cloudwatch-logs-custom"
  }
}

# Adjuntar la policy al role de EC2 (nombre del attachment corregido para evitar duplicados)
resource "aws_iam_role_policy_attachment" "cloudwatch_logs_custom_attachment" {
  role       = aws_iam_role.ec2_app_role.name
  policy_arn = aws_iam_policy.cloudwatch_logs_custom.arn
}

resource "aws_iam_policy" "kms_access" {
  name        = "${var.project_name}-kms-access"
  description = "Permisos para EC2 usar la clave KMS para cifrado"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = var.kms_key_arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "kms_access_attachment" {
  role       = aws_iam_role.ec2_app_role.name
  policy_arn = aws_iam_policy.kms_access.arn
}

# ========================================
# INSTANCES PROFILE PARA EC2
# ========================================

resource "aws_iam_instance_profile" "ec2_app_profile" {
  name = "${var.project_name}-ec2-app-profile"
  role = aws_iam_role.ec2_app_role.name
}

# ========================================
# LAUNCH TEMPLATE
# ========================================

data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_launch_template" "app" {
  name_prefix   = "${var.project_name}-app-"
  image_id      = data.aws_ami.amazon_linux_2023.id
  instance_type = "t2.micro"

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_app_profile.name
  }

  vpc_security_group_ids = [var.app_security_group_id]

  user_data = base64encode(templatefile("${path.module}/userdata.sh", {
  DB_HOST        = var.db_endpoint      # <-- AGREGAR ESTA LÍNEA
  DB_NAME        = var.db_name
  DB_USER       = var.db_username
  DB_PASSWORD        = var.db_password
  project_name   = var.project_name
  aws_region     = data.aws_region.current.id
  log_group_app  = aws_cloudwatch_log_group.app_logs.name
  log_group_system = aws_cloudwatch_log_group.system_logs.name
  enable_xray    = var.enable_xray
}))

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.project_name}-app-instance"
    }
  }
} # <--- ESTA LLAVE FALTABA

# ========================================
# AUTO SCALING GROUP
# ========================================

resource "aws_autoscaling_group" "app" {
  name                 = "${var.project_name}-app-asg"
  vpc_zone_identifier  = var.app_subnet_ids
  min_size             = 1
  max_size             = 3
  desired_capacity     = 1
  health_check_grace_period = 300
  health_check_type    = "EC2"

  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.project_name}-app-asg-instance"
    propagate_at_launch = true
  }
}

# ========================================
# AUTO SCALING POLICY
# ========================================

resource "aws_autoscaling_policy" "cpu_target_tracking" {
  name                   = "${var.project_name}-cpu-target-tracking"
  autoscaling_group_name = aws_autoscaling_group.app.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 70.0
  }
}

# ============================================================================
# CLOUDWATCH LOGS - LOGS LOCALES DE EC2
# ============================================================================

resource "aws_cloudwatch_log_group" "app_logs" {
  name              = "/aws/ec2/${var.project_name}/application"
  retention_in_days = 7

  tags = {
    Name        = "${var.project_name}-ec2-app-logs"
    Module      = "compute"
    Type        = "Local"
    Environment = "dev"
  }
}

resource "aws_cloudwatch_log_group" "system_logs" {
  name              = "/aws/ec2/${var.project_name}/system"
  retention_in_days = 7

  tags = {
    Name   = "${var.project_name}-ec2-system-logs"
    Module = "compute"
    Type   = "Local"
  }
}

# ============================================================================
# IAM POLICY ATTACHMENT - X-RAY (NUEVO)
# ============================================================================

resource "aws_iam_role_policy_attachment" "xray" {
  count      = var.enable_xray ? 1 : 0
  role       = aws_iam_role.ec2_app_role.name
  policy_arn = var.xray_policy_arn
}
