# ========================================
# RDS SUBNET GROUP
# ========================================

resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-db-subnet-group"
  subnet_ids = var.db_subnet_ids

  tags = {
    Name = "${var.project_name}-db-subnet-group"
  }
}

# ========================================
# RDS POSTGRESQL INSTANCE
# ========================================

resource "aws_db_instance" "postgresql" {
  identifier = "${var.project_name}-db"

  # Engine
  engine         = "postgres"
  engine_version = "15.14"

  # Instance
  instance_class        = "db.t3.micro"
  allocated_storage     = 20
  storage_type          = "gp3"
  storage_encrypted     = false

  # Database
  db_name  = var.db_name
  username = var.db_username
  password = var.db_password
  port     = 5432

  # Network
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [var.db_security_group_id]
  publicly_accessible    = false

  # High Availability (desactivado para dev)
  multi_az = false

  # Backup y Maintenance
  backup_retention_period = 0
  skip_final_snapshot     = true
  deletion_protection     = false

  # Monitoring
  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]

  tags = {
    Name = "${var.project_name}-postgresql"
  }
}

# ========================================
# ROUTE 53 PRIVATE HOSTED ZONE
# ========================================

resource "aws_route53_zone" "private" {
  name = "corp.local"

  vpc {
    vpc_id = var.vpc_id
  }

  tags = {
    Name = "${var.project_name}-private-zone"
  }
}

# ========================================
# ROUTE 53 DNS RECORD FOR RDS
# ========================================

resource "aws_route53_record" "db" {
  zone_id = aws_route53_zone.private.zone_id
  name    = "db.corp.local"
  type    = "CNAME"
  ttl     = 300
  records = [aws_db_instance.postgresql.address]
}

# ============================================================================
# CLOUDWATCH LOGS - LOGS LOCALES DE RDS
# ============================================================================
# RDS automáticamente exporta logs a CloudWatch cuando está configurado
# Aquí creamos log groups con retención controlada

# resource "aws_cloudwatch_log_group" "rds_postgresql" {
#   name = "/aws/rds/instance/${aws_db_instance.this.identifier}/postgresql"
#   retention_in_days = 7
# }
 #lifecycle {
  #  ignore_changes = [name]
  #}

  #tags = {
   # Name   = "${var.project_name}-rds-postgresql-logs"
    #Module = "database"
    #ype   = "Local"
 # }
#}

resource "aws_cloudwatch_log_group" "rds_upgrade" {
  name              = "/aws/rds/instance/${aws_db_instance.postgresql.identifier}/upgrade"
  retention_in_days = 30  # Retención más larga para logs de upgrade
  
  tags = {
    Name   = "${var.project_name}-rds-upgrade-logs"
    Module = "database"
    Type   = "Local"
  }
}
