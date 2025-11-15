terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# Proveedor OIDC de GitHub
resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com",
  ]

  thumbprint_list = [
    "a031c46782e6e6c662c2c87c76da9aa62ccabd8e"
  ]

  tags = {
    Name = "GitHub-OIDC-Provider"
  }
}

# IAM Role para GitHub Actions
resource "aws_iam_role" "github_actions" {
  name = "GitHub-Actions-Deploy-Role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:NicolasNunez05/pcfactory-migration-aws:*"
          }
        }
      }
    ]
  })

  tags = {
    Name = "GitHub-Actions-Role"
  }
}

# EC2 Full Access
resource "aws_iam_role_policy_attachment" "ec2_full_access" {
  role       = aws_iam_role.github_actions.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
}

# ECR Access (para push de imágenes Docker)
resource "aws_iam_role_policy_attachment" "ecr_power_user" {
  role       = aws_iam_role.github_actions.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser"
}

# SSM Access (para enviar comandos a EC2)
resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.github_actions.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Outputs
output "github_oidc_provider_arn" {
  value       = aws_iam_openid_connect_provider.github.arn
  description = "ARN del proveedor OIDC"
}

output "github_actions_role_arn" {
  value       = aws_iam_role.github_actions.arn
  description = "ARN de la role que usará GitHub Actions"
}

output "github_actions_role_name" {
  value       = aws_iam_role.github_actions.name
  description = "Nombre de la role"
}
