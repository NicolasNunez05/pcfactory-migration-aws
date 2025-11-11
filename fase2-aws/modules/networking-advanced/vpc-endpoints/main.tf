# =============================================================================
# VPC ENDPOINTS - INTERFACE Y GATEWAY
# =============================================================================
# Comunicación privada con servicios AWS sin Internet Gateway
# =============================================================================

data "aws_region" "current" {}

# =============================================================================
# GATEWAY ENDPOINTS (Sin costo)
# =============================================================================

# S3 Gateway Endpoint
resource "aws_vpc_endpoint" "s3" {
  count = var.enable_s3_gateway ? 1 : 0

  vpc_id            = var.vpc_id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.s3"
  vpc_endpoint_type = "Gateway"

  tags = merge(
    {
      Name = "${var.project_name}-${var.environment}-s3-gateway-endpoint"
    },
    var.tags
  )
}

# DynamoDB Gateway Endpoint
resource "aws_vpc_endpoint" "dynamodb" {
  count = var.enable_dynamodb_gateway ? 1 : 0

  vpc_id            = var.vpc_id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.dynamodb"
  vpc_endpoint_type = "Gateway"

  tags = merge(
    {
      Name = "${var.project_name}-${var.environment}-dynamodb-gateway-endpoint"
    },
    var.tags
  )
}

# =============================================================================
# INTERFACE ENDPOINTS (Con costo - $0.01/hora cada uno)
# =============================================================================

locals {
  interface_endpoints = {
    rds = {
      name    = "rds"
      service = "rds"
      enabled = var.enable_interface_endpoints.rds
    }
    elasticache = {
      name    = "elasticache"
      service = "elasticache"
      enabled = var.enable_interface_endpoints.elasticache
    }
    secretsmanager = {
      name    = "secretsmanager"
      service = "secretsmanager"
      enabled = var.enable_interface_endpoints.secretsmanager
    }
    kms = {
      name    = "kms"
      service = "kms"
      enabled = var.enable_interface_endpoints.kms
    }
    ec2 = {
      name    = "ec2"
      service = "ec2"
      enabled = var.enable_interface_endpoints.ec2
    }
    ec2messages = {
      name    = "ec2messages"
      service = "ec2messages"
      enabled = var.enable_interface_endpoints.ec2messages
    }
    ssm = {
      name    = "ssm"
      service = "ssm"
      enabled = var.enable_interface_endpoints.ssm
    }
    ssmmessages = {
      name    = "ssmmessages"
      service = "ssmmessages"
      enabled = var.enable_interface_endpoints.ssmmessages
    }
    logs = {
      name    = "logs"
      service = "logs"
      enabled = var.enable_interface_endpoints.logs
    }
    monitoring = {
      name    = "monitoring"
      service = "monitoring"
      enabled = var.enable_interface_endpoints.monitoring
    }
    sts = {
      name    = "sts"
      service = "sts"
      enabled = var.enable_interface_endpoints.sts
    }
    sns = {
      name    = "sns"
      service = "sns"
      enabled = var.enable_interface_endpoints.sns
    }
    sqs = {
      name    = "sqs"
      service = "sqs"
      enabled = var.enable_interface_endpoints.sqs
    }
  }

  enabled_endpoints = {
    for k, v in local.interface_endpoints : k => v if v.enabled
  }
}

resource "aws_vpc_endpoint" "interface" {
  for_each = local.enabled_endpoints

  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.${each.value.service}"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.private_subnet_ids
  security_group_ids  = var.security_group_ids
  private_dns_enabled = var.enable_private_dns

  tags = merge(
    {
      Name = "${var.project_name}-${var.environment}-${each.value.name}-endpoint"
    },
    var.tags
  )
}
