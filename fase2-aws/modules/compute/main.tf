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
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMPatchAssociation"
}

resource "aws_iam_role_policy_attachment" "cloudwatch_policy" {
  role       = aws_iam_role.ec2_app_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# ========================================
# ECR POLICY PARA JENKINS (NUEVO)
# ========================================

resource "aws_iam_role_policy_attachment" "ecr_full_access" {
  role       = aws_iam_role.ec2_app_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess"
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

# Adjuntar la policy al role de EC2
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
    DB_HOST        = var.db_endpoint
    DB_NAME        = var.db_name
    DB_USER        = var.db_username
    DB_PASSWORD    = var.db_password
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
}

# ========================================
# JENKINS EC2 INSTANCE (NUEVO)
# ========================================

# Security Group para Jenkins
resource "aws_security_group" "jenkins" {
  name        = "${var.project_name}-jenkins-sg"
  description = "Security group para Jenkins CI/CD"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Jenkins UI"
  }

  ingress {
    from_port   = 50000
    to_port     = 50000
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "Jenkins Agents"
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "SSH"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "All outbound traffic"
  }

  tags = {
    Name = "${var.project_name}-jenkins-sg"
  }
}

# IAM Role para Jenkins
resource "aws_iam_role" "jenkins_role" {
  name = "${var.project_name}-jenkins-role"

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
    Name = "${var.project_name}-jenkins-role"
  }
}

# ECR Full Access para Jenkins
resource "aws_iam_role_policy_attachment" "jenkins_ecr_access" {
  role       = aws_iam_role.jenkins_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess"
}

# EC2 Full Access para Jenkins (necesario para builds)
resource "aws_iam_role_policy_attachment" "jenkins_ec2_access" {
  role       = aws_iam_role.jenkins_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
}

# CloudWatch Logs para Jenkins
resource "aws_iam_role_policy_attachment" "jenkins_cloudwatch_logs" {
  role       = aws_iam_role.jenkins_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
}

# SSM Manager para Jenkins
resource "aws_iam_role_policy_attachment" "jenkins_ssm" {
  role       = aws_iam_role.jenkins_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "jenkins_profile" {
  name = "${var.project_name}-jenkins-profile"
  role = aws_iam_role.jenkins_role.name
}

# Jenkins EC2 Instance
resource "aws_instance" "jenkins" {
  ami                         = data.aws_ami.amazon_linux_2023.id
  instance_type               = "t3.small"
  subnet_id                   = var.web_subnet_ids[0]
  vpc_security_group_ids      = [aws_security_group.jenkins.id]
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.jenkins_profile.name

  user_data = base64encode(<<-EOF
              #!/bin/bash
              set -e
              
              # Update system
              apt-get update
              apt-get upgrade -y
              
              # Install Docker
              apt-get install -y docker.io
              usermod -aG docker ubuntu
              systemctl start docker
              systemctl enable docker
              
              # Install AWS CLI
              apt-get install -y awscli
              
              # Install Git
              apt-get install -y git
              
              # Pull and run Jenkins (Docker)
              docker run -d \
                -p 8080:8080 \
                -p 50000:50000 \
                -v /var/run/docker.sock:/var/run/docker.sock \
                -v jenkins_home:/var/jenkins_home \
                --restart always \
                jenkins/jenkins:lts
              
              # Disable Jenkins security for first access
              sleep 30
              docker exec $(docker ps -q -f name=jenkins) sed -i 's/<useSecurity>true<\/useSecurity>/<useSecurity>false<\/useSecurity>/g' /var/jenkins_home/config.xml || true
              docker restart $(docker ps -q -f name=jenkins)
              
              echo "✅ Jenkins y Docker instalados automáticamente"
              EOF
  )

  tags = {
    Name = "${var.project_name}-jenkins-server"
  }
}

# ========================================
# AUTO SCALING GROUP
# ========================================

resource "aws_autoscaling_group" "app" {
  name                      = "${var.project_name}-app-asg"
  vpc_zone_identifier       = var.app_subnet_ids
  min_size                  = 1
  max_size                  = 3
  desired_capacity          = 1
  health_check_grace_period = 300
  health_check_type         = "EC2"

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
# CLOUDWATCH LOG GROUP PARA JENKINS
# ============================================================================

resource "aws_cloudwatch_log_group" "jenkins_logs" {
  name              = "/aws/ec2/${var.project_name}/jenkins"
  retention_in_days = 30

  tags = {
    Name   = "${var.project_name}-jenkins-logs"
    Module = "compute"
    Type   = "Jenkins"
  }
}

# ============================================================================
# IAM POLICY ATTACHMENT - X-RAY
# ============================================================================

resource "aws_iam_role_policy_attachment" "xray" {
  count      = var.enable_xray ? 1 : 0
  role       = aws_iam_role.ec2_app_role.name
  policy_arn = var.xray_policy_arn
}

# ============================================================================
# OUTPUTS - JENKINS DETAILS
# ============================================================================

output "jenkins_public_ip" {
  value       = aws_instance.jenkins.public_ip
  description = "IP pública de Jenkins"
}

output "jenkins_url" {
  value       = "http://${aws_instance.jenkins.public_ip}:8080"
  description = "URL de Jenkins"
}

output "jenkins_security_group_id" {
  value       = aws_security_group.jenkins.id
  description = "Security Group ID de Jenkins"
}

output "jenkins_instance_id" {
  value       = aws_instance.jenkins.id
  description = "EC2 Instance ID de Jenkins"
}
