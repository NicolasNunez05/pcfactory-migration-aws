# FASE 2: Migración AWS con Terraform - COMPLETO CON TODOS LOS SERVICIOS

## 🎯 Resumen Fase 2

**Objetivo:** Migrar infraestructura on-premise de PCFactory (Docker) a AWS usando Terraform (IaC)

**Servicios AWS Implementados:** 40+ (28 activos + 12 planificados)
**Estado:** ✅ Completado en dev environment  
**Duración Planificada:** 7 días  
**Costo Real:** $82-141/mes (dev), $200-350/mes (prod)

---

## 📊 SERVICIOS AWS IMPLEMENTADOS - FASE 2

### NETWORKING (5 servicios) ✅

| Servicio | Función | Estado | Config |
|----------|---------|--------|--------|
| **VPC** | Red Virtual Privada | ✅ | 10.20.0.0/16, Multi-AZ |
| **Internet Gateway** | Acceso Internet | ✅ | 1 IGW, attached |
| **NAT Gateway** | Salida privadas | ✅ | 1 NAT (us-east-1a), Elastic IP |
| **Route 53** | DNS (privado+público) | ✅ | corp.local zone, 3 records |
| **VPC Flow Logs** | Network monitoring | ✅ | CloudWatch Logs, REJECT traffic |

### COMPUTE (4 servicios) ✅

| Servicio | Función | Estado | Config |
|----------|---------|--------|--------|
| **EC2 Instances** | Compute servers | ✅ | t2.micro, Amazon Linux 2023 |
| **Auto Scaling Group** | Dynamic scaling | ✅ | Min 1, Max 3, CPU-based |
| **Launch Template** | Instance config | ✅ | Python 3.11, Flask bootstrap |
| **Elastic IP** | Static public IP | ✅ | Associated to NAT |

### DATABASE (3 servicios) ✅

| Servicio | Función | Estado | Config |
|----------|---------|--------|--------|
| **RDS PostgreSQL** | Managed database | ✅ | db.t3.micro, Multi-AZ, 20GB |
| **RDS Snapshots** | Automated backups | ✅ | 30-day retention, encrypted |
| **S3 (Backend)** | Terraform state | ✅ | pcfactory-terraform-state |

### SECURITY & IAM (7 servicios) ✅

| Servicio | Función | Estado | Config |
|----------|---------|--------|--------|
| **Security Groups** (3) | Firewall L4 | ✅ | ALB-SG, App-SG, DB-SG |
| **IAM Users** (11) | Identity mgmt | ✅ | 3 admins, 8 operators |
| **IAM Roles** (3) | Role-based access | ✅ | EC2-App, Terraform, CodeDeploy |
| **IAM Policies** (5) | Permission control | ✅ | Least privilege |
| **WAF** | Web app firewall | ✅ | XSS, SQLi, rate limit protection |
| **Secrets Manager** | Credential storage | ✅ | /rds/pcfactory/master |
| **KMS** | Encryption keys | ✅ | CMK for EBS, RDS, S3 |

### LOAD BALANCING (1 servicio) 🚫

| Servicio | Función | Estado | Config |
|----------|---------|--------|--------|
| **ALB** | Traffic distribution | 🚫 Bloqueado* | Code ready, Service Quota limit |

*Service Quota Issue - waiting approval from AWS Support

### MONITORING & LOGGING (8 servicios) ✅

| Servicio | Función | Estado | Config |
|----------|---------|--------|--------|
| **CloudWatch Logs** | Central logging | ✅ | 6 log groups, 7-365 day retention |
| **CloudWatch Metrics** | Performance metrics | ✅ | 20+ dimensions, auto-publish |
| **CloudWatch Alarms** | Alert management | ✅ | 5+ alarms (CPU, RDS, errors) |
| **CloudWatch Dashboard** | Visualization | ✅ | Main + specialized dashboards |
| **CloudTrail** | API audit logging | ✅ | All APIs tracked, S3 storage |
| **X-Ray** | Distributed tracing | ✅ | 5% sampling, service map |
| **SNS Topics** | Notifications | ✅ | 3 topics (critical, warning, info) |
| **Lambda (Future)** | Serverless automation | 📋 | 3 functions planned |

### NETWORKING AVANZADA (Planificado)

| Servicio | Función | Estado | Fase |
|----------|---------|--------|------|
| **Client VPN** | Remote access | 📋 | 2.5 |
| **Network Firewall** | Advanced threat detection | 📋 | 2.5 |
| **ElastiCache Redis** | In-memory caching | 📋 | 2.5 |

### SEGURIDAD AVANZADA (Planificado)

| Servicio | Función | Estado | Fase |
|----------|---------|--------|------|
| **GuardDuty** | Threat detection | 📋 | 2.5 |
| **AWS Config** | Compliance tracking | 📋 | 3 |

### CI/CD & AUTOMATION (Planificado)

| Servicio | Función | Estado | Fase |
|----------|---------|--------|------|
| **CodeDeploy** | App deployment | 📋 | 3 |
| **CodeBuild** | Build automation | 📋 | 3 |
| **GitHub Actions** | CI/CD orchestration | 📋 | 3 |

### CONTAINERS & ORCHESTRATION (Planificado)

| Servicio | Función | Estado | Fase |
|----------|---------|--------|------|
| **ECR** | Docker registry | 📋 | 4 |
| **ECS** | Container orchestration | 📋 | 4 |
| **EKS** | Kubernetes cluster | 📋 | 4 |

### CDN & PERFORMANCE (Planificado)

| Servicio | Función | Estado | Fase |
|----------|---------|--------|------|
| **CloudFront** | Global CDN | 📋 | 3 |

---

## 📋 ARQUITECTURA CON TODOS LOS SERVICIOS

```
┌────────────────────────────────────────────────────────────┐
│ ROUTE 53 (DNS) - corp.local + pcfactory.com              │
└────────┬─────────────────────────────────────────────────┘
         │
┌────────▼─────────────────────────────────────────────────┐
│ INTERNET GATEWAY + WAF (Web App Firewall)               │
│ (DDoS Protection + XSS/SQLi Prevention)                 │
└────────┬─────────────────────────────────────────────────┘
         │
┌────────▼─────────────────────────────────────────────────┐
│ ALB SECURITY GROUP (Firewall L4)                        │
│ Inbound: 80, 443 from 0.0.0.0/0                        │
└────────┬─────────────────────────────────────────────────┘
         │
┌────────▼─────────────────────────────────────────────────┐
│ APPLICATION LOAD BALANCER (Multi-AZ)                    │
│ Health Check: /health (30s interval)                    │
│ Target Group: EC2 instances port 8080                   │
└────────┬─────────────────────────────────────────────────┘
         │
┌────────▼─────────────────────────────────────────────────┐
│ APP SECURITY GROUP (Firewall L4)                        │
│ Inbound: 8080 from ALB-SG                              │
│ Outbound: 5432 to DB, 53 to 0.0.0.0/0                  │
└────────┬─────────────────────────────────────────────────┘
         │
    ┌────┴────┐
    │          │
┌───▼──┐   ┌──▼───┐
│EC2-1 │   │EC2-2 │  Auto Scaling Group (1-3 instances)
│ t2   │   │ t2   │  • Min: 1, Max: 3
│micro │   │micro │  • CPU > 70% → +1 instance
│ IAM  │   │ IAM  │  • CPU < 30% → -1 instance
│ Role │   │ Role │  • Launch Template: Python 3.11
└───┬──┘   └──┬───┘
    │         │
    └────┬────┘
         │ PostgreSQL 5432
┌────────▼─────────────────────────────────────────────────┐
│ DB SECURITY GROUP (Firewall L4)                        │
│ Inbound: 5432 from App-SG only                         │
│ Outbound: DENY all (completamente aislada)            │
└────────┬─────────────────────────────────────────────────┘
         │
    ┌────▼────────────┐
┌───▼──────────┐   ┌──▼──────────┐
│RDS Primary   │   │RDS Standby  │ Multi-AZ
│PostgreSQL 15 │   │(Replica)    │ • Failover < 1min
│us-east-1a   │   │us-east-1b  │ • 30-day backups
│db.t3.micro  │   │Encrypted   │ • PITR enabled
└──────────────┘   └─────────────┘

MONITORING STACK (Todas las capas):
├─ CloudWatch Logs (app, system, db, alb)
├─ CloudWatch Metrics (CPU, memory, network, connections)
├─ CloudWatch Alarms (5+ alarms + escalation)
├─ CloudWatch Dashboards (main + specialized)
├─ VPC Flow Logs (network traffic analysis)
├─ CloudTrail (API audit)
├─ X-Ray (distributed tracing)
└─ SNS Topics (notifications)

SECURITY STACK (IAM):
├─ IAM Users (11 total: 3 admin, 8 ops)
├─ IAM Roles (3: EC2-App, Terraform, CodeDeploy)
├─ Security Groups (3: ALB, App, DB)
├─ WAF Rules (XSS, SQLi, Rate limit)
├─ Secrets Manager (/rds/pcfactory/master)
├─ KMS Keys (EBS, RDS, S3 encryption)
└─ IAM Policies (least privilege)
```

---

## 🔌 ESPECIFICACIONES DETALLADAS DE SERVICIOS

### VPC Configuration
- CIDR: 10.20.0.0/16
- IPv6: Dual-stack enabled
- DNS Resolution: Enabled
- DNS Hostnames: Enabled

### Subnets (6 total)
```
Public: 10.20.10.0/24 (AZ-a), 10.20.11.0/24 (AZ-b)
App:    10.20.20.0/24 (AZ-a), 10.20.21.0/24 (AZ-b)
DB:     10.20.30.0/24 (AZ-a), 10.20.31.0/24 (AZ-b)
```

### Route 53 Records
```
db.corp.local      → RDS PostgreSQL endpoint
app.corp.local     → ALB endpoint (when deployed)
pcfactory.com      → Route 53 public (optional)
```

### RDS PostgreSQL Configuration
- Engine: PostgreSQL 14.7+
- Instance: db.t3.micro
- Storage: 20GB gp3 (auto-scale 5-100GB)
- Multi-AZ: Yes with failover replica
- Backup: 30 days PITR, daily snapshots
- Encryption: KMS at-rest, SSL/TLS in-transit

### EC2 Auto Scaling Group
- Instance Type: t2.micro
- AMI: Amazon Linux 2023
- Min: 1, Max: 3, Desired: 1
- Health Check: ALB, 30s interval
- Scaling: CPU-based (+1 at 70%, -1 at 30%)

### IAM Configuration
- **Users**: 11 (3 admin + 8 operators)
- **Roles**: 3 (EC2-App, Terraform, CodeDeploy)
- **Policies**: 5 (least privilege design)
- **Groups**: 2 (AdministradoresCloud, UsuariosAplicacion)

### CloudWatch Setup
- Log Groups: 6
- Custom Metrics: 20+
- Alarms: 5+ (CPU, RDS, errors, network)
- Dashboards: 3+ (main, infra, app, security)
- Retention: 7-365 days

### Security Stack
- Security Groups: 3 (ALB, App, DB)
- WAF Rules: 5+ (XSS, SQLi, rate limit)
- KMS Keys: 3 (RDS, EBS, S3)
- Secrets Manager: 1 (/rds/pcfactory/master)
- Network Firewall: Ready (optional, $24/mo)

---

## 📊 TOTAL SERVICIOS POR CATEGORÍA

| Categoría | Activos | Planificados | Total |
|-----------|---------|--------------|-------|
| Networking | 5 | 3 | 8 |
| Compute | 4 | 0 | 4 |
| Database | 3 | 0 | 3 |
| Security/IAM | 7 | 2 | 9 |
| Monitoring | 8 | 0 | 8 |
| Load Balancing | 0 | 1 | 1 |
| Automation/CI-CD | 0 | 3 | 3 |
| Containers | 0 | 3 | 3 |
| Performance/CDN | 0 | 1 | 1 |
| **TOTAL** | **28** | **13** | **41** |

---

## ✅ DEPLOYMENT CHECKLIST

Servicios Implementados:
- [x] VPC Multi-AZ
- [x] 6 Subnets configuradas
- [x] Internet Gateway + NAT Gateway
- [x] Route 53 Private Zone
- [x] EC2 Auto Scaling Group
- [x] RDS PostgreSQL Multi-AZ
- [x] 3 Security Groups
- [x] 11 IAM Users + 3 Roles
- [x] WAF Rules
- [x] KMS Encryption
- [x] Secrets Manager
- [x] CloudWatch (Logs, Metrics, Alarms, Dashboard)
- [x] VPC Flow Logs
- [x] CloudTrail
- [x] X-Ray Tracing
- [x] SNS Topics
- [x] S3 Terraform Backend
- [x] DynamoDB State Locking

Servicios Bloqueados:
- [ ] ALB (Service Quota - code ready)
- [ ] Network Firewall (optional, code ready)

Servicios Planificados (Fase 3):
- [ ] Client VPN
- [ ] GuardDuty
- [ ] AWS Config
- [ ] CodeDeploy
- [ ] CodeBuild
- [ ] Lambda Functions
- [ ] ElastiCache Redis
- [ ] CloudFront CDN

Servicios Planificados (Fase 4):
- [ ] ECR
- [ ] ECS
- [ ] EKS

---

**Fase 2 Status:** ✅ COMPLETADA (95%)

**Próxima Fase:** Fase 3 - CI/CD Pipeline

*Última actualización: 15 de noviembre de 2025*  
*Proyecto: PCFactory Migration AWS - Capstone DuocUC 2025*
