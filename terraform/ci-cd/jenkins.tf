# Buscar la VPC por tag (sin necesidad de tfstate)
data "aws_vpc" "pcfactory" {
  filter {
    name   = "tag:Name"
    values = ["pcfactory"]
  }
}

# Obtener subnets de esa VPC
data "aws_subnets" "pcfactory" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.pcfactory.id]
  }
  
  filter {
    name   = "tag:Type"
    values = ["Private"]  # O la subnet que uses
  }
}

# SSH Key Pair
resource "aws_key_pair" "jenkins" {
  key_name   = "pcfactory-jenkins-key"
  public_key = var.jenkins_public_key
}

# Security Group
resource "aws_security_group" "jenkins" {
  name        = "pcfactory-jenkins-sg"
  description = "Security group para Jenkins"
  vpc_id      = data.aws_vpc.pcfactory.id  # ← AUTOMÁTICO

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "pcfactory-jenkins-sg"
  }
}

# IAM Role
resource "aws_iam_role" "jenkins" {
  name = "pcfactory-jenkins-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# IAM Policy
resource "aws_iam_policy" "jenkins_ecr" {
  name        = "pcfactory-jenkins-ecr-policy"
  description = "Policy para Jenkins acceder a ECR"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:DescribeRepositories"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "jenkins_ecr" {
  role       = aws_iam_role.jenkins.name
  policy_arn = aws_iam_policy.jenkins_ecr.arn
}

resource "aws_iam_instance_profile" "jenkins" {
  name = "pcfactory-jenkins-profile"
  role = aws_iam_role.jenkins.name
}

# EC2 Jenkins
resource "aws_instance" "jenkins" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t3.medium"
  key_name                    = aws_key_pair.jenkins.key_name
  
  iam_instance_profile        = aws_iam_instance_profile.jenkins.name
  associate_public_ip_address = true

  user_data = base64encode(templatefile("${path.module}/jenkins_setup.sh", {
    ecr_repository_url = aws_ecr_repository.pcfactory.repository_url
  }))

  tags = {
    Name        = "pcfactory-jenkins"
    Environment = var.environment
    Project     = "PCFactory"
  }

  root_block_device {
    volume_size           = 30
    volume_type           = "gp3"
    delete_on_termination = true
  }

  depends_on = [aws_ecr_repository.pcfactory]
}
