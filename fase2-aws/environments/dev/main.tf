# =============================================================================
# PCFACTORY MIGRATION - INFRASTRUCTURE AS CODE (TERRAFORM)
# Environment: Development
# AWS Region: us-east-1
# =============================================================================

# ============================================
# DATA SOURCE: Buscar VPC dinámicamente
# ============================================
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.project_name}-vpc"
  }
}
# ==========================================
# NETWORKING MODULE
# ==========================================
module "networking" {
  source = "../../modules/network"

  project_name       = var.project_name
  vpc_cidr           = var.vpc_cidr
  availability_zones = var.availability_zones
  nat_gateway_id     = module.security.nat_gateway_id
}

# ========================================
# SECURITY MODULE
# ========================================
module "security" {
  source            = "../../modules/security"
  vpc_id            = module.networking.vpc_id
  project_name      = "pcfactory-migration"
  public_subnet_ids = module.networking.public_subnet_ids
}

# ========================================
# NETWORK FIREWALL MODULE
# ========================================
module "network_firewall" {
  source = "../../modules/network-firewall"

  project_name        = "pcfactory-migration"
  vpc_id              = module.networking.vpc_id
  firewall_subnet_ids = module.networking.public_subnet_ids

  # NUEVAS variables SNS
  sns_topic_critical_arn = module.sns.critical_topic_arn
  sns_topic_warning_arn  = module.sns.warning_topic_arn
  environment            = "dev"
}

# ========================================
# DATABASE MODULE
# ========================================
module "database" {
  source = "../../modules/database"

  project_name         = "pcfactory-migration"
  vpc_id               = module.networking.vpc_id
  db_subnet_ids        = module.networking.private_db_subnet_ids
  db_security_group_id = module.security.db_sg_id

  db_username = "pcfactory"
  db_password = "PCFactory2024!"
  db_name     = "pcfactory"

  # NUEVAS variables SNS
  sns_topic_critical_arn = module.sns.critical_topic_arn
  sns_topic_warning_arn  = module.sns.warning_topic_arn
  environment            = "dev"
}

# ========================================
# COMPUTE MODULE
# ========================================
module "compute" {
  source = "../../modules/compute"

  project_name          = "pcfactory-migration"
  vpc_id                = module.networking.vpc_id
  app_subnet_ids        = module.networking.private_app_subnet_ids
  app_security_group_id = module.security.app_sg_id

  db_endpoint = module.database.db_endpoint
  db_name     = "pcfactory"
  db_username = "pcfactory"
  db_password = "PCFactory2024!"

  sns_topic_critical_arn = module.sns.critical_topic_arn
  sns_topic_warning_arn  = module.sns.warning_topic_arn
  environment            = "dev"

  enable_xray     = true
  xray_policy_arn = module.xray.xray_policy_arn

  kms_key_arn = module.kms.key_arn


  # Comentar esta línea porque ALB no está disponible
  # target_group_arn = module.load_balancer.target_group_arn
}

# ========================================
# CLIENT VPN MODULE
# ========================================
module "client_vpn" {
  source = "../../modules/client-vpn"

  project_name                = "pcfactory-migration"
  vpc_id                      = module.networking.vpc_id
  vpn_subnet_ids              = module.networking.private_app_subnet_ids
  server_certificate_arn      = "arn:aws:acm:us-east-1:787124622819:certificate/b3b882a3-5f35-4aae-8b43-0e9aa3bb206f"
  client_root_certificate_arn = "arn:aws:acm:us-east-1:787124622819:certificate/2c130541-efc0-4b2b-a90d-1dd5423b7130"
  vpn_cidr                    = "172.16.0.0/22"

  # NUEVAS variables SNS
  sns_topic_critical_arn = module.sns.critical_topic_arn
  sns_topic_warning_arn  = module.sns.warning_topic_arn
  environment            = "dev"
}

module "kms" {
  source = "../../modules/kms"

  project_name            = var.project_name
  environment             = "dev"
  description             = "Clave KMS para cifrado PCFactory dev"
  key_name                = "pcfactory-dev-kms-key"
  alias_name              = "pcfactory-dev-key"
  enable_key_rotation     = true
  deletion_window_in_days = 30

  tags = {
    Owner = "team-security"
  }
}

module "waf" {
  source       = "../../modules/waf"
  project_name = var.project_name
  environment  = "dev"
  # alb_arn = module.load_balancer.alb_arn  # Comentado pues load_balancer no está activo aún
}


# ============================================================================
# SNS TOPICS - NOTIFICACIONES
# ============================================================================
module "sns" {
  source = "../../modules/monitoring/sns"

  project_name   = var.project_name
  environment    = "dev"
  email_endpoint = "nicolasnunezalvarezaws@gmail.com"
  sms_endpoint   = "+56981972292" # Chile - Formato internacional
  enable_sms     = true
}

# ============================================================================
# AWS X-RAY - DISTRIBUTED TRACING
# ============================================================================
module "xray" {
  source = "../../modules/monitoring/xray"

  project_name          = var.project_name
  environment           = "dev"
  enable_xray_insights  = false # Activar en prod (costo adicional)
  enable_xray_alarms    = true
  default_sampling_rate = 0.05 # 5% de requests

  # SNS para alarmas
  sns_topic_critical_arn = module.sns.critical_topic_arn
  sns_topic_warning_arn  = module.sns.warning_topic_arn
}

# ============================================================================
# MONITORING MODULE - CLOUDWATCH LOGS CENTRALIZADO
# ============================================================================
module "monitoring" {
  source = "../../modules/monitoring/cloudwatch-logs"

  project_name               = var.project_name
  environment                = "dev"
  retention_days_centralized = 90
  retention_days_security    = 365
  enable_encryption          = false

  local_log_groups = {
    "ec2-app" = {
      name = module.compute.app_log_group_name
      arn  = module.compute.app_log_group_arn
      type = "application"
    }

    "ec2-system" = {
      name = module.compute.system_log_group_name
      arn  = module.compute.system_log_group_arn
      type = "infrastructure"
    }

    # COMENTAR ESTA SECCIÓN (RDS):
    # "rds-postgresql" = {
    #   name = module.database.rds_postgresql_log_group_name
    #   arn  = module.database.rds_postgresql_log_group_arn
    #   type = "application"
    # }

    "vpn-connections" = {
      name = module.client_vpn.vpn_log_group_name
      arn  = module.client_vpn.vpn_log_group_arn
      type = "security"
    }

    "firewall-flow" = {
      name = module.network_firewall.firewall_flow_log_group_name
      arn  = module.network_firewall.firewall_flow_log_group_arn
      type = "infrastructure"
    }

    "firewall-alert" = {
      name = module.network_firewall.firewall_alert_log_group_name
      arn  = module.network_firewall.firewall_alert_log_group_arn
      type = "security"
    }
  }
}

# ============================================================================
# CLOUDWATCH COMPOSITE ALARMS - MÓDULO CENTRALIZADO
# ============================================================================
module "cloudwatch_alarms" {
  source = "../../modules/monitoring/cloudwatch-alarms"

  project_name           = var.project_name
  environment            = "dev"
  sns_topic_critical_arn = module.sns.critical_topic_arn
  sns_topic_warning_arn  = module.sns.warning_topic_arn

  # Nombres de alarmas de cada módulo (para Composite Alarms)
  ec2_alarm_names = module.compute.ec2_alarm_names
  rds_alarm_names = module.database.rds_alarm_names
  # alb_alarm_names      = module.load_balancer.alb_alarm_names  # Descomentar cuando actives ALB
  vpn_alarm_names      = module.client_vpn.vpn_alarm_names
  firewall_alarm_names = module.network_firewall.firewall_alarm_names
}

# ============================================================================
# VPC FLOW LOGS - MONITOREO DE RED
# ============================================================================
module "vpc_flow_logs" {
  source = "../../modules/monitoring/vpc-flow-logs"

  project_name      = var.project_name
  environment       = "dev"
  vpc_id            = module.networking.vpc_id
  public_subnet_ids = module.networking.public_subnet_ids

  # Configuración de Flow Logs
  traffic_type           = "REJECT" # Solo tráfico rechazado (reduce costos 70%)
  retention_days         = 30       # Logs VPC: 30 días
  retention_days_subnets = 7        # Logs subnets: 7 días
  enable_subnet_logs     = true     # Flow Logs adicionales en subnets públicas
  enable_encryption      = false    # Activar en prod

  # SNS para alarmas de seguridad
  sns_topic_critical_arn = module.sns.critical_topic_arn
  sns_topic_warning_arn  = module.sns.warning_topic_arn
}

# ============================================================================
# CLOUDWATCH DASHBOARDS - VISUALIZACIÓN
# ============================================================================
# COMENTADO TEMPORALMENTE - Problemas con tipos de datos en métricas
# module "dashboards" {
#   source = "../../modules/monitoring/dashboards"
#
#   project_name = var.project_name
#   environment  = "dev"
#   aws_region   = "us-east-1"
#
#   # IDs de recursos para métricas
#   asg_name        = module.compute.autoscaling_group_name
#   db_instance_id  = module.database.db_instance_id
#   vpn_endpoint_id = module.client_vpn.vpn_endpoint_id
#   firewall_name   = module.network_firewall.firewall_name
#
#   # ALB (comentar si ALB está deshabilitado)
#   # alb_arn_suffix           = module.load_balancer.alb_arn_suffix
#   # target_group_arn_suffix  = module.load_balancer.target_group_arn_suffix
#   # enable_alb_widgets       = true
#
#   # Si ALB está comentado, usar valores por defecto
#   alb_arn_suffix          = ""
#   target_group_arn_suffix = ""
#   enable_alb_widgets      = false
# }

# ============================================================================
# LAMBDA FUNCTIONS - AUTOMATIZACIÓN
# ============================================================================

# ----------------------------------------------------------------------------
# 1. LAMBDA LOG PARSER
# ----------------------------------------------------------------------------
module "lambda_log_parser" {
  source = "../../modules/automation/lambda-log-parser"

  project_name          = var.project_name
  environment           = "dev"
  source_log_group_name = module.monitoring.centralized_app_log_group_name
  source_log_group_arn  = module.monitoring.centralized_app_log_group_arn
  filter_pattern        = "" # "" = todos los logs, o usar filtro específico
  sns_topic_warning_arn = module.sns.warning_topic_arn
}

# ----------------------------------------------------------------------------
# 2. LAMBDA ALARM RESPONDER (AUTO-REMEDIATION)
# ----------------------------------------------------------------------------
module "lambda_alarm_responder" {
  source = "../../modules/automation/lambda-alarm-responder"

  project_name           = var.project_name
  environment            = "dev"
  alarm_topic_arn        = module.sns.critical_topic_arn # Se subscribe a alarmas críticas
  notification_topic_arn = module.sns.info_topic_arn     # Notifica acciones tomadas
}

# ----------------------------------------------------------------------------
# 3. LAMBDA SNAPSHOT MANAGER
# ----------------------------------------------------------------------------
module "lambda_snapshot_manager" {
  source = "../../modules/automation/lambda-snapshot-manager"

  project_name           = var.project_name
  environment            = "dev"
  notification_topic_arn = module.sns.info_topic_arn
  sns_topic_critical_arn = module.sns.critical_topic_arn
  retention_days         = 7                   # 7 días de retención
  schedule_expression    = "cron(0 2 * * ? *)" # 2 AM UTC diario

  # Otros ejemplos de schedule:
  # "cron(0 6 * * ? *)"      # 6 AM UTC (3 AM Chile) diario
  # "cron(0 0 * * SUN *)"    # Domingos a medianoche
  # "rate(1 day)"            # Cada 24 horas
}

module "ssm_patch_manager" {
  source = "../../modules/operations/ssm-patch-manager"

  project_name        = var.project_name
  environment         = "dev"
  instance_ids        = []                    # Vacío porque usamos ASG
  schedule_expression = "cron(0 2 ? * SUN *)" # Domingos 2 AM
}

# =============================================================================
# SECRETS MANAGER CON ROTACIÓN
# =============================================================================

module "secrets_manager" {
  source = "../../modules/secrets-manager"

  # Identificación
  project_name = var.project_name
  environment  = "dev"

  # RDS Credentials
  rds_endpoint = module.database.db_endpoint
  rds_username = "pcfactory"
  rds_password = var.rds_master_password
  rds_db_name  = "pcfactory"
  rds_port     = 5432

  # Redis Credentials
  redis_endpoint   = module.elasticache_redis.configuration_endpoint_address
  redis_auth_token = random_password.redis_auth_token.result
  redis_port       = 6379

  # Rotation Settings
  enable_rds_rotation        = true
  rotation_days              = 30
  rotation_lambda_subnet_ids = module.networking.private_app_subnet_ids
  rotation_lambda_sg_ids     = [module.security.app_sg_id]

  # KMS Encryption
  kms_key_arn = module.kms.key_arn

  # Recovery
  recovery_window_days = 30

  tags = {
    Team       = "Security"
    CostCenter = "IT-Security"
  }

  depends_on = [
    module.database,
    module.elasticache_redis,
    module.kms,
    module.monitoring
  ]
}


# =============================================================================
# ELASTICACHE REDIS
# =============================================================================

# Generar auth token aleatorio para Redis
resource "random_password" "redis_auth_token" {
  length           = 32
  special          = true
  override_special = "!&#$^<>-"
}

module "s3storage" {
  source       = "../../modules/storage/s3"
  project_name = var.project_name
  environment  = var.environment
  kms_key_id   = var.kms_key_id       # <--- Agrega esta línea con el valor, variable o hardcoded
  # otras variables que uses
}

module "configrules" {
  source = "../../modules/compliance/config-rules"  # Ruta relativa desde dev hasta modules/compliance/config-rules
  project_name = var.project_name
  environment  = var.environment
  s3_bucket_name = module.s3storage.logs_bucket_name  # Asegúrate de exportar este output en módulo S3
  # otras variables que uses
}

module "elasticache_redis" {
  source = "../../modules/cache/elasticache-redis"

  # Identificación del proyecto
  project_name = var.project_name
  environment  = "dev"

  # Configuración de red
  vpc_id             = module.networking.vpc_id
  private_subnet_ids = module.networking.private_app_subnet_ids # CORREGIDO

  # Security groups
  allowed_security_group_ids = [module.security.app_sg_id] # CORREGIDO

  # Resto de la configuración sin cambios...
  node_type               = "cache.t4g.micro"
  num_node_groups         = 3
  replicas_per_node_group = 2
  redis_version           = "7.1"
  port                    = 6379
  parameter_group_family  = "redis7"

  multi_az_enabled           = true
  automatic_failover_enabled = true

  transit_encryption_enabled = true
  at_rest_encryption_enabled = true
  kms_key_id                 = module.monitoring.kms_key_arn
  auth_token_enabled         = true
  auth_token                 = random_password.redis_auth_token.result

  snapshot_retention_limit = 7
  snapshot_window          = "03:00-05:00"

  maintenance_window         = "sun:06:00-sun:08:00" # Ventana de mantenimiento: Domingo 6am-8am
  auto_minor_version_upgrade = true

  tags = {
    Team       = "DevOps"
    CostCenter = "IT-Operations"
    CacheType  = "Session-DB-API"
  }

  depends_on = [
    module.networking,
    module.monitoring
  ]
}

# =============================================================================
# COST MANAGEMENT - AWS BUDGETS
# =============================================================================

module "aws_budgets" {
  source = "../../modules/cost-management/budgets"

  # Identificación
  project_name = var.project_name
  environment  = "dev"

  # Presupuesto global
  global_monthly_budget      = 50
  alert_threshold_percentage = 80

  # Presupuestos por servicio
  enable_service_budgets     = true
  ec2_monthly_budget         = 20
  rds_monthly_budget         = 10
  s3_monthly_budget          = 5
  elasticache_monthly_budget = 10
  other_services_budget      = 5

  # Notificaciones
  notification_emails = [
    "nicolasnunezalvarezaws@gmail.com"
  ]

  # Configuración
  notification_type   = "ACTUAL"
  comparison_operator = "GREATER_THAN"
  time_unit           = "MONTHLY"

  tags = {
    Team       = "DevOps"
    CostCenter = "IT-Operations"
  }
}

# =============================================================================
# STORAGE - S3 BUCKETS
# =============================================================================

module "s3_storage" {
  source = "../../modules/storage/s3"

  project_name = var.project_name
  environment  = "dev" # <-- Valor fijo o usa local.environment si existe

  # KMS para cifrado de buckets
  kms_key_id = module.monitoring.kms_key_arn

  # Habilitar buckets
  enable_backups_bucket   = true
  enable_logs_bucket      = true
  enable_artifacts_bucket = true

  # Configuración de lifecycle - Backups
  backups_standard_days           = 30
  backups_ia_days                 = 90
  backups_glacier_days            = 365
  backups_noncurrent_version_days = 90

  # Configuración de lifecycle - Logs
  logs_standard_days   = 30
  logs_ia_days         = 90
  logs_expiration_days = 90

  # Configuración de lifecycle - Artifacts
  artifacts_standard_days           = 60
  artifacts_ia_days                 = 180
  artifacts_noncurrent_version_days = 60

  # Configuración general
  enable_mfa_delete         = false
  incomplete_multipart_days = 7
  enable_access_logging     = true

  # Tags adicionales
  tags = {
    Team       = "DevOps"
    CostCenter = "IT-Operations"
    Compliance = "Required"
  }

  depends_on = [
    module.monitoring
  ]
}

# =============================================================================
# SECURITY ADVANCED - IAM ACCESS ANALYZER
# =============================================================================

module "iam_access_analyzer" {
  source = "../../modules/security-advanced/iam-access-analyzer"

  project_name           = var.project_name
  environment            = "dev"
  analyzer_type          = "ACCOUNT"
  enable_unused_access   = true
  unused_access_age_days = 90

  tags = {
    Team = "Security"
  }
}

# =============================================================================
# SECURITY ADVANCED - GUARDDUTY
# =============================================================================

module "guardduty" {
  source = "../../modules/security-advanced/guardduty"

  project_name                 = var.project_name
  environment                  = "dev"
  enable_s3_protection         = true
  enable_kubernetes_protection = false
  enable_malware_protection    = true
  enable_runtime_monitoring    = true
  finding_publishing_frequency = "FIFTEEN_MINUTES"
  sns_topic_arn                = module.sns.critical_topic_arn

  tags = {
    Team = "Security"
  }

  depends_on = [module.sns] # <-- Ya lo tienes, pero asegúrate que esté
}

# =============================================================================
# SECURITY ADVANCED - SECURITY HUB
# =============================================================================

module "security_hub" {
  source = "../../modules/security-advanced/security-hub"

  project_name                     = var.project_name
  environment                      = "dev"
  enable_default_standards         = true
  enable_aws_foundational_security = true
  enable_cis_aws_foundations_v1_4  = true
  enable_pci_dss                   = false
  enable_nist                      = false
  control_finding_generator        = "SECURITY_CONTROL"
  auto_enable_controls             = true
  sns_topic_arn                    = module.sns.critical_topic_arn

  tags = {
    Team = "Security"
  }

  depends_on = [
    module.guardduty,
    module.iam_access_analyzer
  ]
}

# =============================================================================
# NETWORKING ADVANCED - VPC ENDPOINTS
# =============================================================================

module "vpc_endpoints" {
  source = "../../modules/networking-advanced/vpc-endpoints"

  project_name       = var.project_name
  environment        = "dev"
  vpc_id             = module.networking.vpc_id
  private_subnet_ids = module.networking.private_app_subnet_ids
  security_group_ids = [module.security.app_sg_id]

  enable_s3_gateway       = true
  enable_dynamodb_gateway = false

  enable_interface_endpoints = {
    rds            = true
    elasticache    = true
    secretsmanager = true
    kms            = true
    ec2            = true
    ec2messages    = true
    ssm            = true
    ssmmessages    = true
    logs           = true
    monitoring     = true
    sts            = true
    sns            = true
    sqs            = false
  }

  enable_private_dns = true

  tags = {
    Team = "Networking"
  }

  depends_on = [module.networking]
}

# =============================================================================
# COMPLIANCE - AWS CONFIG RULES
# =============================================================================

module "config_rules" {
  source = "../../modules/compliance/config-rules"

  project_name         = var.project_name
  environment          = "dev"
  s3_bucket_name       = module.s3_storage.logs_bucket_id
  sns_topic_arn        = module.sns.warning_topic_arn
  enable_managed_rules = true
  recording_frequency  = "CONTINUOUS"
  enable_all_supported = true

  tags = {
    Team = "Compliance"
  }

  depends_on = [
    module.s3_storage,
    module.sns
  ]
}

# =============================================================================
# MONITORING - ANOMALY DETECTION
# =============================================================================

module "anomaly_detection" {
  source = "../../modules/monitoring/anomaly-detection"

  project_name           = var.project_name
  environment            = "dev"
  sns_topic_arn          = module.sns.critical_topic_arn
  enable_cpu_anomaly     = true
  enable_db_anomaly      = true
  enable_network_anomaly = true
  enable_request_anomaly = true
  anomaly_band_width     = 2
  evaluation_periods     = 2

  tags = {
    Team = "DevOps"
  }

  depends_on = [module.sns]
}

# =============================================================================
# AUTOMATION - LAMBDA REMEDIATION
# =============================================================================

module "lambda_remediation" {
  source = "../../modules/automation/lambda-remediation"

  project_name           = var.project_name
  environment            = "dev"
  enable_sg_remediation  = true
  enable_s3_remediation  = true
  enable_iam_remediation = false
  sns_topic_arn          = module.sns.critical_topic_arn

  tags = {
    Team = "Security"
  }

  depends_on = [
    module.security_hub,
    module.sns
  ]
}

# =============================================================================
# AUTOMATION - SSM AUTOMATION
# =============================================================================

module "ssm_automation" {
  source = "../../modules/automation/ssm-automation"

  project_name               = var.project_name
  environment                = "dev"
  enable_backup_automation   = true
  enable_patching_automation = true
  enable_snapshot_automation = true
  backup_schedule            = "cron(0 2 * * ? *)"
  patching_schedule          = "cron(0 3 ? * SUN *)"
  snapshot_retention_days    = 7
  sns_topic_arn              = module.sns.info_topic_arn

  tags = {
    Team = "DevOps"
  }

  depends_on = [module.sns]
}

# ========================================
# LOAD BALANCER MODULE
# ========================================
# ESTADO: Comentado - Descomentar cuando esté listo para desplegar
# Descomentar cuando:
# 1. Verificar que alb_sg_id esté disponible en module.security
# 2. Ejecutar: terraform plan (para revisar cambios)
# 3. Ejecutar: terraform apply (para desplegar ALB)
# ========================================
# module "load_balancer" {
#   source          = "../../modules/load-balancer"
#   project_name    = var.project_name
#   vpc_id          = module.networking.vpc_id
#   public_subnets  = module.networking.public_subnet_ids
#   alb_sg_id       = module.security.alb_sg_id
#   
#   # NUEVAS variables SNS
#   sns_topic_critical_arn = module.sns.critical_topic_arn
#   sns_topic_warning_arn  = module.sns.warning_topic_arn
#   environment            = "dev"
# }

# =============================================================================
# MÓDULO: DNS - ROUTE 53 PÚBLICA (COMENTADO)
# =============================================================================
# ESTADO: Completamente comentado - Listo para activación futura
#
# REQUISITOS PARA ACTIVAR:
# 1. Descomentar y desplegar módulo "load_balancer" (arriba)
# 2. Verificar que ALB esté funcionando correctamente
# 3. Comprar un dominio real (ej: pcfactory.com)
# 4. Descomentar este módulo completo
# 5. Descomentar variables y outputs en modules/dns/
# 6. Ejecutar: terraform init, terraform plan, terraform apply
#
# DEPENDENCIAS:
# - module.load_balancer.alb_dns_name
# - module.load_balancer.alb_zone_id
#
# COSTO ESTIMADO:
# - Hosted Zone pública: $0.50 USD/mes
# - Dominio: $12-15 USD/año (si lo registras en Route 53)
# - Queries DNS: Primeros 1B/mes = $0.40 por millón adicionales
# =============================================================================

# module "dns" {
#   source       = "../../modules/dns"
#   project_name = var.project_name
#   environment  = "production"
#   
#   # Dominio real - CAMBIAR por tu dominio cuando lo compres
#   domain = "pcfactory.com"
#   
#   # Obtener desde módulo load_balancer
#   alb_dns_name = module.load_balancer.alb_dns_name
#   alb_zone_id  = module.load_balancer.alb_zone_id
#   
#   # Configuración opcional
#   enable_health_check = false  # Cambiar a true si deseas monitoreo ($0.50/mes)
#   health_check_path   = "/health"
#   ttl_short           = 300   # 5 minutos
#   ttl_long            = 3600  # 1 hora
# }

# ========================================
# OUTPUTS - NETWORKING
# ========================================


output "public_subnet_ids" {
  description = "IDs de las subredes públicas"
  value       = module.networking.public_subnet_ids
}

output "private_app_subnet_ids" {
  description = "IDs de las subredes privadas de aplicación"
  value       = module.networking.private_app_subnet_ids
}

output "private_db_subnet_ids" {
  description = "IDs de las subredes privadas de base de datos"
  value       = module.networking.private_db_subnet_ids
}

output "igw_id" {
  description = "ID del Internet Gateway"
  value       = module.networking.igw_id
}

output "vpc_ipv6_cidr_block" {
  description = "Bloque CIDR IPv6 de la VPC"
  value       = module.networking.vpc_ipv6_cidr_block
}

output "eigw_id" {
  description = "ID del Egress-Only Internet Gateway"
  value       = module.networking.eigw_id
}

output "public_subnet_ipv6_cidrs" {
  description = "Bloques CIDR IPv6 de subnets públicas"
  value       = module.networking.public_subnet_ipv6_cidr_blocks
}

# ========================================
# OUTPUTS - DATABASE
# ========================================
output "db_endpoint" {
  description = "Endpoint de la base de datos RDS"
  value       = module.database.db_endpoint
}

output "db_dns_name" {
  description = "Nombre DNS privado de la base de datos (Route 53 privada - corp.local)"
  value       = module.database.db_dns_name
}

# ========================================
# OUTPUTS - COMPUTE
# ========================================
output "autoscaling_group_name" {
  description = "Nombre del Auto Scaling Group"
  value       = module.compute.autoscaling_group_name
}

# ============================================================================
# OUTPUTS - MONITORING (CLOUDWATCH LOGS)
# ============================================================================
output "centralized_app_log_group" {
  description = "Log group centralizado de aplicación"
  value       = module.monitoring.centralized_app_log_group_name
}

output "centralized_infra_log_group" {
  description = "Log group centralizado de infraestructura"
  value       = module.monitoring.centralized_infra_log_group_name
}

output "centralized_security_log_group" {
  description = "Log group centralizado de seguridad"
  value       = module.monitoring.centralized_security_log_group_name
}

# ============================================================================
# OUTPUTS - SNS TOPICS
# ============================================================================
output "sns_critical_topic_arn" {
  description = "ARN del topic SNS para alarmas críticas (Email + SMS)"
  value       = module.sns.critical_topic_arn
}

output "sns_warning_topic_arn" {
  description = "ARN del topic SNS para alarmas de advertencia (Solo Email)"
  value       = module.sns.warning_topic_arn
}

output "sns_info_topic_arn" {
  description = "ARN del topic SNS para notificaciones informativas"
  value       = module.sns.info_topic_arn
}

# ============================================================================
# OUTPUTS - CLOUDWATCH ALARMS
# ============================================================================
output "ec2_composite_alarm_arn" {
  description = "ARN de la alarma compuesta de EC2"
  value       = module.cloudwatch_alarms.ec2_composite_alarm_arn
}

output "rds_composite_alarm_arn" {
  description = "ARN de la alarma compuesta de RDS"
  value       = module.cloudwatch_alarms.rds_composite_alarm_arn
}

output "application_composite_alarm_arn" {
  description = "ARN de la alarma compuesta de aplicación completa (EC2 + RDS)"
  value       = module.cloudwatch_alarms.application_composite_alarm_arn
}

output "infrastructure_composite_alarm_arn" {
  description = "ARN de la alarma compuesta de infraestructura (VPN + Firewall)"
  value       = module.cloudwatch_alarms.infrastructure_composite_alarm_arn
}

# ============================================================================
# OUTPUTS - VPC FLOW LOGS
# ============================================================================
output "vpc_flow_log_group_name" {
  description = "Nombre del log group de VPC Flow Logs"
  value       = module.vpc_flow_logs.vpc_flow_log_group_name
}

output "vpc_flow_log_id" {
  description = "ID del VPC Flow Log"
  value       = module.vpc_flow_logs.vpc_flow_log_id
}

# =============================================================================
# SECURITY ADVANCED OUTPUTS
# =============================================================================

output "iam_access_analyzer_arn" {
  description = "ARN del IAM Access Analyzer"
  value       = module.iam_access_analyzer.analyzer_arn
}

output "guardduty_detector_id" {
  description = "ID del GuardDuty detector"
  value       = module.guardduty.detector_id
}

output "security_hub_arn" {
  description = "ARN de Security Hub"
  value       = module.security_hub.security_hub_arn
}

output "security_hub_standards" {
  description = "Estándares de seguridad habilitados"
  value       = module.security_hub.enabled_standards
}

# =============================================================================
# NETWORKING ADVANCED OUTPUTS
# =============================================================================

output "vpc_endpoints_count" {
  description = "Número de VPC endpoints interface creados"
  value       = module.vpc_endpoints.enabled_endpoints_count
}

output "vpc_endpoints_cost_estimate" {
  description = "Estimación de costo mensual de VPC endpoints"
  value       = module.vpc_endpoints.monthly_cost_estimate
}

# =============================================================================
# COMPLIANCE OUTPUTS
# =============================================================================

output "config_recorder_id" {
  description = "ID del AWS Config recorder"
  value       = module.config_rules.config_recorder_id
}

output "config_rules_enabled" {
  description = "Número de reglas Config habilitadas"
  value       = module.config_rules.enabled_rules_count
}

# =============================================================================
# MONITORING OUTPUTS
# =============================================================================

output "anomaly_detectors_enabled" {
  description = "Detectores de anomalías habilitados"
  value       = module.anomaly_detection.enabled_detectors
}

# =============================================================================
# AUTOMATION OUTPUTS
# =============================================================================

output "lambda_remediation_enabled" {
  description = "Remediaciones Lambda habilitadas"
  value       = module.lambda_remediation.enabled_remediations
}

output "ssm_automation_enabled" {
  description = "Automatizaciones SSM habilitadas"
  value       = module.ssm_automation.enabled_automations
}

output "ssm_automation_schedules" {
  description = "Horarios de automatización SSM"
  value       = module.ssm_automation.automation_schedules
}

# =============================================================================
# SECRETS MANAGER OUTPUTS
# =============================================================================

output "rds_secret_arn" {
  description = "ARN del secret de RDS"
  value       = module.secrets_manager.rds_secret_arn
  sensitive   = true
}

output "redis_secret_arn" {
  description = "ARN del secret de Redis"
  value       = module.secrets_manager.redis_secret_arn
  sensitive   = true
}

output "rds_rotation_enabled" {
  description = "Indica si rotación RDS está habilitada"
  value       = module.secrets_manager.rds_rotation_enabled
}


# ============================================================================
# OUTPUTS - CLOUDWATCH DASHBOARDS (COMENTADO TEMPORALMENTE)
# ============================================================================
# output "dashboard_overview_url" {
#   description = "URL del dashboard Overview"
#   value       = module.dashboards.dashboard_urls["overview"]
# }
#
# output "dashboard_networking_url" {
#   description = "URL del dashboard Networking"
#   value       = module.dashboards.dashboard_urls["networking"]
# }
#
# output "dashboard_compute_url" {
#   description = "URL del dashboard Compute"
#   value       = module.dashboards.dashboard_urls["compute"]
# }
#
# output "dashboard_database_url" {
#   description = "URL del dashboard Database"
#   value       = module.dashboards.dashboard_urls["database"]
# }
#
# output "dashboard_security_url" {
#   description = "URL del dashboard Security"
#   value       = module.dashboards.dashboard_urls["security"]
# }
#
# output "all_dashboards" {
#   description = "Lista de todos los dashboards"
#   value       = module.dashboards.all_dashboard_names
# }


# ============================================================================
# OUTPUTS - AWS X-RAY
# ============================================================================
output "xray_sampling_rule_id" {
  description = "ID de la regla de sampling de X-Ray"
  value       = module.xray.xray_sampling_rule_id
}

output "xray_group_errors_arn" {
  description = "ARN del grupo X-Ray para errores"
  value       = module.xray.xray_group_errors_arn
}

output "xray_group_slow_arn" {
  description = "ARN del grupo X-Ray para requests lentos"
  value       = module.xray.xray_group_slow_arn
}

output "xray_enabled" {
  description = "Estado de X-Ray (habilitado/deshabilitado)"
  value       = true
}

# ============================================================================
# OUTPUTS - LAMBDA FUNCTIONS
# ============================================================================

output "lambda_log_parser_arn" {
  description = "ARN de Lambda Log Parser"
  value       = module.lambda_log_parser.lambda_function_arn
}

output "lambda_alarm_responder_arn" {
  description = "ARN de Lambda Alarm Responder"
  value       = module.lambda_alarm_responder.lambda_function_arn
}

output "lambda_snapshot_manager_arn" {
  description = "ARN de Lambda Snapshot Manager"
  value       = module.lambda_snapshot_manager.lambda_function_arn
}

output "snapshot_schedule" {
  description = "Schedule configurado para snapshots RDS"
  value       = module.lambda_snapshot_manager.schedule_expression
}

# =============================================================================
# S3 STORAGE OUTPUTS
# =============================================================================

output "s3_backups_bucket_id" {
  description = "ID del bucket S3 de backups"
  value       = module.s3_storage.backups_bucket_id
}

output "s3_backups_bucket_arn" {
  description = "ARN del bucket S3 de backups"
  value       = module.s3_storage.backups_bucket_arn
}

output "s3_logs_bucket_id" {
  description = "ID del bucket S3 de logs"
  value       = module.s3_storage.logs_bucket_id
}

output "s3_logs_bucket_arn" {
  description = "ARN del bucket S3 de logs"
  value       = module.s3_storage.logs_bucket_arn
}

output "s3_artifacts_bucket_id" {
  description = "ID del bucket S3 de artifacts"
  value       = module.s3_storage.artifacts_bucket_id
}

output "s3_artifacts_bucket_arn" {
  description = "ARN del bucket S3 de artifacts"
  value       = module.s3_storage.artifacts_bucket_arn
}

output "s3_all_bucket_arns" {
  description = "Lista de todos los ARNs de buckets S3 creados"
  value       = module.s3_storage.all_bucket_arns
}

# =============================================================================
# ELASTICACHE REDIS OUTPUTS
# =============================================================================

output "redis_configuration_endpoint" {
  description = "Configuration endpoint de Redis (Cluster Mode)"
  value       = module.elasticache_redis.configuration_endpoint_address
  sensitive   = false
}

output "redis_port" {
  description = "Puerto de Redis"
  value       = module.elasticache_redis.port
}

output "redis_security_group_id" {
  description = "ID del security group de Redis"
  value       = module.elasticache_redis.security_group_id
}

output "redis_total_nodes" {
  description = "Número total de nodos en el cluster Redis"
  value       = module.elasticache_redis.total_nodes
}

output "redis_auth_token" {
  description = "Token de autenticación de Redis"
  value       = random_password.redis_auth_token.result
  sensitive   = true
}

# =============================================================================
# COST MANAGEMENT OUTPUTS
# =============================================================================

output "budget_sns_topic_arn" {
  description = "ARN del SNS topic para alertas de presupuesto"
  value       = module.aws_budgets.sns_topic_arn
}

output "total_monthly_budget" {
  description = "Presupuesto mensual total configurado"
  value       = module.aws_budgets.total_monthly_budget
}

output "global_budget_name" {
  description = "Nombre del presupuesto global"
  value       = module.aws_budgets.global_budget_name
}

# ========================================
# OUTPUTS - LOAD BALANCER (COMENTADO)
# ========================================
# Descomentar cuando actives module "load_balancer"
# ========================================
# output "alb_dns_name" {
#   description = "DNS del Application Load Balancer"
#   value       = module.load_balancer.alb_dns_name
# }

# output "alb_zone_id" {
#   description = "Zone ID del ALB (para usar en Route 53)"
#   value       = module.load_balancer.alb_zone_id
# }

# output "alb_arn" {
#   description = "ARN del Application Load Balancer"
#   value       = module.load_balancer.alb_arn
# }

# output "alb_url" {
#   description = "URL completa del Application Load Balancer"
#   value       = "http://${module.load_balancer.alb_dns_name}"
# }

# ========================================
# OUTPUTS - DNS (COMENTADO)
# ========================================
# Descomentar cuando actives module "dns"
# ========================================
# output "dns_zone_id" {
#   description = "ID de la zona pública Route 53"
#   value       = module.dns.zone_id
# }

# output "dns_zone_name" {
#   description = "Nombre de la zona DNS (dominio público)"
#   value       = module.dns.zone_name
# }

# output "dns_name_servers" {
#   description = "Name servers para configurar en registrador externo"
#   value       = module.dns.zone_name_servers
# }

# output "app_fqdn" {
#   description = "FQDN completo de la aplicación (app.pcfactory.com)"
#   value       = module.dns.app_fqdn
# }

# output "apex_fqdn" {
#   description = "FQDN del dominio raíz (pcfactory.com)"
#   value       = module.dns.apex_fqdn
# }

# output "www_fqdn" {
#   description = "FQDN de WWW (www.pcfactory.com)"
#   value       = module.dns.www_fqdn
# }

# output "api_fqdn" {
#   description = "FQDN de API (api.pcfactory.com)"
#   value       = module.dns.api_fqdn
# }

# output "app_url" {
#   description = "URL completa de la aplicación (HTTPS)"
#   value       = "https://${module.dns.app_fqdn}"
# }

# output "www_url" {
#   description = "URL completa de WWW (HTTPS)"
#   value       = "https://${module.dns.www_fqdn}"
# }

# output "api_url" {
#   description = "URL completa de API (HTTPS)"
#   value       = "https://${module.dns.api_fqdn}"
# }

# =============================================================================
# PLAN DE ACTIVACIÓN
# =============================================================================
#
# PASO 1: ACTIVAR ALB
# ─────────────────────────────────────────────────────────────────────────
# 1. Descomentar module "load_balancer" (arriba)
# 2. Descomentar outputs de ALB
# 3. Descomentar línea alb_alarm_names en module.cloudwatch_alarms
# 4. Ejecutar:
#    $ terraform plan          # Revisar cambios
#    $ terraform apply         # Desplegar ALB
# 5. Verificar:
#    $ terraform output alb_dns_name
#    $ curl http://<alb_dns_name>
#
# PASO 2: ACTIVAR DNS PÚBLICO
# ─────────────────────────────────────────────────────────────────────────
# 1. Comprar dominio real (ej: pcfactory.com)
#    - Opción A: Route 53 (integración más fácil con Terraform)
#    - Opción B: GoDaddy/NameCheap (configura Name Servers después)
#
# 2. Descomentar:
#    - module "dns" (este archivo)
#    - variables en modules/dns/variables.tf
#    - outputs en modules/dns/outputs.tf
#    - outputs de DNS (este archivo)
#
# 3. Actualizar variable dominio:
#    domain = "pcfactory.com"  # Tu dominio real
#
# 4. Ejecutar:
#    $ terraform init          # Detectar nuevo módulo
#    $ terraform plan          # Revisar cambios
#    $ terraform apply         # Desplegar Route 53
#
# 5. Configurar Name Servers (si compraste en registrador externo):
#    $ terraform output dns_name_servers
#    # Copiar los 4 name servers y configurar en registrador
#
# 6. Esperar propagación (24-48 horas típico)
#
# 7. Validar:
#    $ nslookup app.pcfactory.com
#    $ dig app.pcfactory.com
#    $ curl https://app.pcfactory.com
#
# =============================================================================

resource "aws_s3_bucket" "logs" {
  bucket        = "pcfactory-migration-logs-dev"
  force_destroy = true  # <-- Agregar esta línea
  # ... resto de tu config
}