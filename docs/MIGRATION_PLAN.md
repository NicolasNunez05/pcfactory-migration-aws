# MIGRATION_PLAN.md - VERSIÓN V2 COMPLETO CON TODOS LOS SERVICIOS

## 📅 Plan de Migración PCFactory a AWS - COMPLETO

**Objetivo:** Migración segura de infraestructura PCFactory on-premise a AWS

**Duración Total:** 4 fases (8 semanas)  
**Servicios Involucrados:** 41 AWS services
**Metodología:** Phased migration con validaciones
**Rollback:** Plan de contingencia en cada fase

---

## 🗺️ ROADMAP: 4 FASES CON TODOS LOS SERVICIOS

### FASE 1: Blueprint On-Premise ✅ COMPLETADA

**Servicios Utilizados:**
- Docker (simulación on-premise)
- Docker Compose (orquestación local)
- Nginx (web server)
- Flask (aplicación)
- PostgreSQL (base de datos)
- Samba4 (AD simulado)
- DNS local

**Validación:**
```bash
✅ docker-compose up (todos servicios)
✅ Acceso a aplicación vía localhost
✅ Database populated
✅ DNS resolution funciona
```

---

### FASE 2: Migración AWS ✅ EN PROGRESO (95%)

**Servicios AWS Implementados (28 activos):**

#### Networking (5)
- ✅ VPC (10.20.0.0/16)
- ✅ Internet Gateway
- ✅ NAT Gateway
- ✅ Route 53 (corp.local)
- ✅ VPC Flow Logs

#### Compute (4)
- ✅ EC2 Instances (t2.micro)
- ✅ Auto Scaling Group (1-3)
- ✅ Launch Template
- ✅ Elastic IP

#### Database (3)
- ✅ RDS PostgreSQL Multi-AZ
- ✅ RDS Automated Snapshots
- ✅ S3 Terraform Backend

#### Security/IAM (7)
- ✅ Security Groups (3: ALB, App, DB)
- ✅ IAM Users (11: 3 admin, 8 ops)
- ✅ IAM Roles (3: EC2-App, Terraform, CodeDeploy)
- ✅ IAM Policies (5 - least privilege)
- ✅ WAF (XSS, SQLi protection)
- ✅ Secrets Manager (/rds/pcfactory/master)
- ✅ KMS (EBS, RDS, S3 encryption)

#### Load Balancing (1)
- 🚫 ALB (Service Quota bloqueado - código ready)

#### Monitoring (8)
- ✅ CloudWatch Logs (6 log groups)
- ✅ CloudWatch Metrics (20+ dimensions)
- ✅ CloudWatch Alarms (5+)
- ✅ CloudWatch Dashboards
- ✅ CloudTrail (API audit)
- ✅ X-Ray (distributed tracing)
- ✅ SNS Topics (3)
- ✅ VPC Flow Logs (network monitoring)

**Servicios Bloqueados/Planificados Fase 2 (3):**
- 📋 Client VPN (access remoto)
- 📋 Network Firewall (IDS/IPS - optional $24/mo)
- 📋 ElastiCache Redis (caching)

**Estado Actual:**
```
✅ 28 servicios activos
🚫 1 servicio bloqueado (ALB - Service Quota)
📋 3 servicios planificados (VPN, NFW, Redis)
```

---

### FASE 3: CI/CD Pipeline 📋 PLANIFICADA (3-5 días)

**Servicios AWS (3):**
- 📋 CodeDeploy (deployment automation)
- 📋 CodeBuild (build process)
- 📋 Lambda (3 functions - serverless automation)

**Herramientas Externas:**
- GitHub Actions (CI/CD orchestration)

**Servicios Previos Utilizados:**
- S3 (artifact storage)
- SNS (notifications)
- CloudWatch (monitoring)
- IAM Roles (CodeDeploy execution role)

**Servicios Agregados:**
- 📋 CloudFront (CDN - optional)
- 📋 GuardDuty (threat detection)
- 📋 AWS Config (compliance)

**Success Criteria:**
- Deploy frequency: 1-2x daily
- Lead time: < 1 hour
- MTTR: < 5 minutes
- Change failure rate: < 5%

---

### FASE 4: Modernización Kubernetes 📋 FUTURO (2 semanas)

**Servicios AWS (3):**
- 📋 ECR (Elastic Container Registry - Docker images)
- 📋 ECS (Elastic Container Service - containers)
- 📋 EKS (Elastic Kubernetes Service - orchestration)

**Servicios Complementarios:**
- CloudWatch (container monitoring)
- IAM (ECS/EKS task roles)
- VPC (networking for containers)
- Secrets Manager (container secrets)
- ECR (image storage)

---

## 📊 MATRIZ COMPLETA: SERVICIOS POR FASE

| Servicio | Fase 1 | Fase 2 | Fase 3 | Fase 4 | Total |
|----------|--------|--------|--------|--------|-------|
| **Networking** (5) | Docker | VPC, IGW, NAT, Route53 | CloudFront | - | 5 |
| **Compute** (4) | - | EC2, ASG, LT, EIP | Lambda | - | 4 |
| **Database** (3) | PostgreSQL | RDS, Snapshots, S3 | - | - | 3 |
| **Security** (7) | - | SG, IAM, WAF, KMS, Secrets | GuardDuty, Config | - | 7 |
| **Load Balancing** (1) | - | ALB (bloqueado) | - | - | 1 |
| **Monitoring** (8) | - | CloudWatch, CloudTrail, SNS, XRay | - | - | 8 |
| **CI/CD** (3) | - | - | CodeDeploy, CodeBuild, GitHub Actions | - | 3 |
| **Containers** (3) | Docker | - | - | ECR, ECS, EKS | 3 |
| **Total por Fase** | 2 | 28 | 8 | 3 | **41** |

---

## 🔄 PLAN DE MIGRACIÓN DE DATOS

### Estrategia: PostgreSQL Multi-AZ Failover

```
PASO 1: Evaluación
├─ Tamaño: ~50MB
├─ Tablas: 5 principales
├─ Constraints: Foreign keys activas
└─ Stored procedures: None

PASO 2: Crear RDS Target
├─ Engine: PostgreSQL 15
├─ Multi-AZ: Primary + Standby
├─ Backups: 30 días PITR

PASO 3: Migración
├─ Tool: AWS DMS (Database Migration Service)
├─ Método: Full load + CDC
├─ Downtime: < 5 min

PASO 4: Validación
├─ Row count verification
├─ Checksum validation
├─ Index integrity
├─ Constraints check

PASO 5: Cutover
├─ DNS switch (db.corp.local → RDS)
├─ Application reconnect
├─ Monitoring 24h

PASO 6: Rollback (if needed)
├─ Time: < 15 minutes
├─ Keep on-prem 30 days
├─ Replication one-way (RDS → on-prem)
```

---

## ⚙️ PLAN DE CUTOVER (Migration Day)

### Timeline Recomendado (Viernes 5:00 PM - Sábado 9:00 AM)

```
VIERNES 5:00 PM - Inicio
├─ Notificar stakeholders
├─ Freeze cambios BD
└─ Validar health checks

VIERNES 5:30 PM - Backup Final
├─ pg_dump on-premise
├─ Upload a S3
└─ Calcular checksums

VIERNES 6:00 PM - Migración de Datos
├─ AWS DMS full load
├─ Validar row counts
├─ Verificar integridad

VIERNES 6:30 PM - Testing
├─ Smoke tests
├─ CloudWatch metrics
├─ Application connectivity

VIERNES 7:00 PM - DNS Switch
├─ Route 53 update
├─ db.corp.local → RDS
└─ Application reconnect

VIERNES 8:00 PM - Validation (1 hora)
├─ /products endpoint test
├─ Database queries
├─ Performance check

VIERNES 9:00 PM - Monitoring 24h
├─ CloudWatch active
├─ Alarms configured
└─ Ready for rollback

SÁBADO 9:00 AM - Post-Migration
├─ 24h validation successful
├─ Deprecate on-premise DB
└─ Archive backups
```

---

## 🚨 ESCENARIOS DE ROLLBACK

| Escenario | RTO | Acción |
|-----------|-----|--------|
| **RDS inaccesible** | 30 min | NO hacer DNS switch |
| **Datos corruptos** | 15 min | Revert a backup |
| **Performance poor** | 10 min | Revert DNS, investigar |
| **Conexión fallida** | 5 min | Config revert |

---

## 📋 SERVICIOS POR VALIDACIÓN

### Pre-Migration Validations
```bash
# Servicios verificados:
✅ S3 (terraform state backup exists)
✅ RDS (target ready + Multi-AZ)
✅ EC2 (instances healthy)
✅ Security Groups (rules correct)
✅ IAM Roles (permissions validated)
✅ CloudWatch (alarms configured)
✅ Route 53 (DNS records ready)
✅ KMS (keys accessible)
```

### During-Migration Validations
```bash
# Servicios monitoreados:
✅ RDS (migration status)
✅ CloudWatch Logs (errors)
✅ CloudTrail (API calls)
✅ VPC Flow Logs (network)
✅ SNS (notifications)
✅ Secrets Manager (credentials)
```

### Post-Migration Validations
```bash
# Servicios verificados 24h:
✅ RDS Snapshots (automated running)
✅ CloudWatch Metrics (normal values)
✅ CloudWatch Alarms (no false alerts)
✅ X-Ray (traces showing)
✅ CloudTrail (logging active)
✅ Auto Scaling (responding correctly)
```

---

## ✅ CHECKLIST MIGRACIÓN COMPLETO

**Pre-Migration (1 semana antes):**
- [ ] Comunicar a stakeholders
- [ ] Validar backups on-premise
- [ ] Test restore en AWS
- [ ] Revisar Security Groups
- [ ] Validar IAM Roles
- [ ] Preparar Lambda functions (future)
- [ ] Configurar CloudWatch alarms

**Migration Day:**
- [ ] Crear RDS snapshot pre-migracion
- [ ] Migrar datos (AWS DMS o pg_dump)
- [ ] Validar checksums
- [ ] Switchear Route 53
- [ ] Monitorear 24h
- [ ] Update documentation

**Post-Migration (24h después):**
- [ ] Validar 24h sin errores
- [ ] Deprecate on-premise
- [ ] Archive backups a Glacier
- [ ] Lessons learned session
- [ ] Team training completado

---

## 📊 TOTAL SERVICIOS MIGRACIÓN

| Categoría | Total | Activos | Bloqueados | Planificados |
|-----------|-------|---------|-----------|--------------|
| Fase 1-2 | 28 | 28 | 1 | 3 |
| Fase 3 | 8 | 0 | 0 | 8 |
| Fase 4 | 3 | 0 | 0 | 3 |
| **TOTAL** | **41** | **28** | **1** | **13** |

---

**Plan de Migración V2:** Completo con 41 servicios  
**Última actualización:** 15 de noviembre de 2025  
**Proyecto:** PCFactory Migration AWS - Capstone DuocUC 2025
