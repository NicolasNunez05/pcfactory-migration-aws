variable "aws_region" {
  default = "us-east-1"
}

variable "vpc_id" {
  description = "VPC ID de Fase 2"
  type        = string
}

variable "jenkins_public_key" {
  description = "SSH public key para Jenkins"
  type        = string
  sensitive   = true
}

variable "app_name" {
  default = "pcfactory-app"
}

variable "environment" {
  default = "production"
}