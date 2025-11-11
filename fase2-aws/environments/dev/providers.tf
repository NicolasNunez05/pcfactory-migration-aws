terraform {
  backend "s3" {
    bucket         = "pcfactory-terraform-state-787124622819"
    key            = "pcfactory-migration/dev/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "pcfactory-terraform-locks"
  }

  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}