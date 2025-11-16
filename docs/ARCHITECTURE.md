# ARCHITECTURE.md - VERSIÓN V2 COMPLETO CON TODOS LOS SERVICIOS

## 📐 Visión General de Arquitectura - COMPLETO

Este documento describe la **arquitectura completa** de la migración de infraestructura PCFactory desde on-premise a AWS usando Terraform como Infrastructure as Code.

**Proyecto:** PCFactory Migration AWS  
**Capstone:** DuocUC 2025  
**Carrera:** Ingeniería en Conectividad y Redes  
**Autor:** Nicolás Núñez Álvarez  
**Servicios Totales:** 41 (28 activos + 13 planificados)

---

## 🏗️ MATRIZ DE SERVICIOS AWS POR COMPONENTE

### ACCESO & ENTRADA (3 servicios)

| Componente | Servicio | Función | Estado |
|-----------|----------|---------|--------|
| DNS | **Route 53** (Private + Public) | corp.local + pcfactory.com | ✅ Activo |
| Internet | **Internet Gateway** | Conexión Internet pública | ✅ Activo |
| Security | **WAF** | Web Application Firewall | ✅ Activo |

### NETWORKING & RED (7 servicios)

| Componente | Servicio | Función | Estado |
|-----------|----------|---------|--------|
| VPC | **VPC** | Red privada 10.20.0.0/16 | ✅ Activo |
| Subnets | **Subnets** (6) | 2 públicas, 2 app privadas, 2 db privadas | ✅ Activo |
| NAT | **NAT Gateway** | Salida a Internet desde privadas | ✅ Activo |
| Elastic IP | **Elastic IP** | IP estática para NAT | ✅ Activo |
| Monitoring | **VPC Flow Logs** | Análisis tráfico de red | ✅ Activo |
| Future | **Client VPN** | Acceso remoto (plannned) | 📋 Diseño |
| Future | **Network Firewall** | Protección avanzada (optional) | 📋 Diseño |

### COMPUTE (4 servicios)

| Componente | Servicio | Función | Estado |
|-----------|----------|---------|--------|
| Servers | **EC2 Instances** | t2.micro, 1-3 instances | ✅ Activo |
| Scaling | **Auto Scaling Group** | Escalado automático por CPU | ✅ Activo |
| Template | **Launch Template** | Configuración de instancias | ✅ Activo |
| ElastiCache | **ElastiCache Redis** | Caching en memoria (planned) | 📋 Futuro |

### LOAD BALANCING (2 servicios)

| Componente | Servicio | Función | Estado |
|-----------|----------|---------|--------|
| Distributor | **ALB** | Application Load Balancer Multi-AZ | 🚫 Bloqueado* |
| Target Groups | **Target Groups** | Destinos ALB | 🚫 Bloqueado* |

*Service Quota issue - code ready, awaiting AWS approval

### DATABASE (3 servicios)

| Componente | Servicio | Función | Estado |
|-----------|----------|---------|--------|
| Database | **RDS PostgreSQL** | db.t3.micro Multi-AZ, 20GB | ✅ Activo |
| Backups | **RDS Snapshots** | Backups automáticos 30 días | ✅ Activo |
| S3 Storage | **S3** (3 buckets) | Terraform state, backups, logs | ✅ Activo |

### SECURITY & IDENTITY (7 servicios)

| Componente | Servicio | Función | Estado |
|-----------|----------|---------|--------|
| Firewall | **Security Groups** (3) | ALB-SG, App-SG, DB-SG | ✅ Activo |
| Users | **IAM Users** (11) | 3 admins + 8 operators | ✅ Activo |
| Roles | **IAM Roles** (3) | EC2-App, Terraform, CodeDeploy | ✅ Activo |
| Policies | **IAM Policies** (5) | Least privilege | ✅ Activo |
| Encryption | **KMS** | Customer Master Keys | ✅ Activo |
| Secrets | **Secrets Manager** | /rds/pcfactory/master | ✅ Activo |
| Future | **GuardDuty** | Threat detection (planned) | 📋 Futuro |

### MONITORING & LOGGING (8 servicios)

| Componente | Servicio | Función | Estado |
|-----------|----------|---------|--------|
| Logs | **CloudWatch Logs** | Central logging (6 log groups) | ✅ Activo |
| Metrics | **CloudWatch Metrics** | Performance metrics (20+ dimensions) | ✅ Activo |
| Alarms | **CloudWatch Alarms** | Alert management (5+ alarms) | ✅ Activo |
| Dashboard | **CloudWatch Dashboard** | Visualization | ✅ Activo |
| Audit | **CloudTrail** | API audit logging | ✅ Activo |
| Tracing | **X-Ray** | Distributed tracing | ✅ Activo |
| Notifications | **SNS** | 3 Topics (critical, warning, info) | ✅ Activo |
| Compliance | **AWS Config** | Compliance tracking (planned) | 📋 Futuro |

### CI/CD & AUTOMATION (3 servicios)

| Componente | Servicio | Función | Estado |
|-----------|----------|---------|--------|
| Deploy | **CodeDeploy** | Application deployment (planned) | 📋 Fase 3 |
| Build | **CodeBuild** | Build automation (planned) | 📋 Fase 3 |
| Serverless | **Lambda** (3 functions) | Automation (planned) | 📋 Fase 3 |

### CONTAINERS & ORCHESTRATION (3 servicios)

| Componente | Servicio | Función | Estado |
|-----------|----------|---------|--------|
| Registry | **ECR** | Docker container registry (planned) | 📋 Fase 4 |
| Orchestration | **ECS** | Container orchestration (planned) | 📋 Fase 4 |
| Kubernetes | **EKS** | Kubernetes cluster (planned) | 📋 Fase 4 |

### PERFORMANCE & CDN (1 servicio)

| Componente | Servicio | Función | Estado |
|-----------|----------|---------|--------|
| CDN | **CloudFront** | Global content delivery (planned) | 📋 Fase 3 |

---

## 📊 ARQUITECTURA POR CAPAS CON TODOS LOS SERVICIOS

```
CAPA 1: ACCESO GLOBAL
├─ Route 53 (DNS público corp.local + pcfactory.com)
├─ CloudFront (CDN global - futuro)
└─ Internet Gateway (conexión Internet)

         ↓ (HTTPS/HTTP 80,443)

CAPA 2: SEGURIDAD PERIMETRAL
├─ WAF (XSS, SQLi, Rate limiting)
├─ Network Firewall (IDS/IPS - opcional $24/mo)
├─ AWS Shield (DDoS protection - included)
└─ Security Groups (ALB-SG: inbound 80,443)

         ↓ (Tráfico permitido)

CAPA 3: DISTRIBUCIÓN DE CARGA
├─ ALB (Application Load Balancer - bloqueado)
├─ Target Groups (destinos dinámicos)
├─ Elastic IP (IP estática NAT)
└─ CloudWatch (monitoreo ALB)

         ↓ (Puerto 8080)

CAPA 4: APLICACIÓN
├─ EC2 Auto Scaling Group (1-3 instancias)
│  ├─ Instance Type: t2.micro
│  ├─ AMI: Amazon Linux 2023
│  ├─ Runtime: Python 3.11 + Flask
│  └─ IAM Role: EC2-App-Role
├─ Launch Template (configuración blueprint)
├─ Security Group: App-SG (inbound 8080 from ALB)
├─ CloudWatch Logs (app logs /aws/ec2/flask)
├─ CloudWatch Metrics (CPU, memory, network)
├─ X-Ray (distributed tracing)
├─ VPC Flow Logs (network traffic analysis)
└─ ElastiCache Redis (caching - futuro)

         ↓ (PostgreSQL 5432)

CAPA 5: DATOS
├─ RDS PostgreSQL Multi-AZ
│  ├─ Primary: us-east-1a
│  ├─ Standby: us-east-1b (automatic failover)
│  ├─ Backups: 30 días PITR
│  ├─ Encryption: KMS at-rest
│  └─ SSL/TLS in-transit
├─ RDS Snapshots (daily automated)
├─ S3 (Terraform state, backups, logs)
├─ Security Group: DB-SG (inbound 5432 from App-SG only)
├─ KMS (Master keys para encriptación)
├─ Route 53 Private Zone (db.corp.local → RDS endpoint)
└─ Secrets Manager (/rds/pcfactory/master credentials)

CAPA 6: IDENTIDAD & ACCESO
├─ IAM Users (11: 3 admin, 8 ops)
├─ IAM Roles (3: EC2-App, Terraform, CodeDeploy)
├─ IAM Policies (least privilege - 5 policies)
├─ IAM Groups (AdministradoresCloud, UsuariosAplicacion)
├─ KMS (encryption keys access control)
├─ Secrets Manager (credential access)
└─ Session Manager (acesso sin SSH)

CAPA 7: AUDITORÍA & COMPLIANCE
├─ CloudTrail (API logging - all services)
├─ CloudWatch Logs (application logs aggregation)
├─ VPC Flow Logs (network traffic forensics)
├─ X-Ray (service map & tracing)
├─ AWS Config (compliance rules - future)
└─ GuardDuty (threat detection - future)

CAPA 8: AUTOMATIZACIÓN & DESPLIEGUE
├─ GitHub Actions (CI/CD workflows - future)
├─ CodeDeploy (deployment automation - future)
├─ CodeBuild (build process - future)
├─ Lambda (serverless automation - future)
├─ ECR/ECS/EKS (containers - future)
└─ Terraform (Infrastructure as Code - active)
```

---

## 🔄 FLUJO DE DATOS CON SERVICIOS

```
CLIENTE (Internet)
  │ HTTPS Request
  ├─→ Route 53 DNS Resolution (DNS Query)
  ├─→ CloudFront (CDN - future)
  ├─→ Internet Gateway (Public entry point)
  ├─→ WAF (Web Application Firewall)
  │   ├─ Check: XSS patterns
  │   ├─ Check: SQL Injection
  │   └─ Check: Rate limiting
  ├─→ Network Firewall (IDS/IPS inspection)
  │   ├─ DPI (Deep Packet Inspection)
  │   ├─ Threat pattern matching
  │   └─ Botnet detection
  ├─→ ALB Security Group (Layer 4 firewall)
  │   └─ Inbound: 80, 443 from 0.0.0.0/0
  ├─→ Application Load Balancer
  │   ├─ Parse HTTP headers
  │   ├─ Health check: /health
  │   ├─ Select healthy target (EC2)
  │   └─ CloudWatch: log request
  ├─→ App Security Group (Layer 4 firewall)
  │   └─ Inbound: 8080 from ALB-SG only
  ├─→ EC2 Instance (Flask Application)
  │   ├─ Parse request
  │   ├─ Assume IAM Role (EC2-App-Role)
  │   ├─ CloudWatch Logs: app logs
  │   ├─ X-Ray: segment creation
  │   └─ Retrieve secrets from Secrets Manager
  ├─→ RDS Security Group (Layer 4 firewall)
  │   └─ Inbound: 5432 from App-SG only
  ├─→ RDS PostgreSQL
  │   ├─ SSL/TLS connection
  │   ├─ Execute query (SELECT * FROM products)
  │   ├─ KMS: decrypt data at-rest
  │   ├─ Return results
  │   └─ Log query (RDS logs)
  ├─→ EC2 Response generation
  │   ├─ JSON serialization
  │   ├─ CloudWatch: response time metric
  │   └─ X-Ray: subsegment complete
  ├─→ ALB
  │   ├─ CloudWatch Logs: HTTP access log
  │   ├─ Add compression (gzip)
  │   └─ Return response
  └─→ CLIENTE Receives HTTP 200 + JSON body

BACKGROUND MONITORING:
  ├─ CloudWatch Metrics (every 1-5 minutes)
  │   ├─ EC2: CPU, memory, network
  │   ├─ RDS: connections, CPU, IOPS
  │   └─ ALB: requests, response time
  ├─ CloudWatch Alarms (continuous)
  │   ├─ CPU > 80% → SNS notification
  │   ├─ RDS connections > 80 → SNS notification
  │   └─ Error rate > 1% → SNS notification
  ├─ VPC Flow Logs (all packets)
  │   └─ Store in CloudWatch Logs
  ├─ CloudTrail (all API calls)
  │   └─ Store in S3 + CloudWatch
  ├─ ElastiCache (caching - future)
  │   └─ Cache frequent queries
  └─ Auto Scaling (continuous monitoring)
      └─ Increase/decrease instances based on load
```

---

## 📊 RESUMEN: 41 SERVICIOS TOTALES

| Categoría | Activos | Planificados | Total |
|-----------|---------|--------------|-------|
| Networking | 5 | 3 | 8 |
| Compute | 4 | 1 | 5 |
| Database | 3 | 0 | 3 |
| Load Balancing | 0 | 1 | 1 |
| Security/IAM | 7 | 1 | 8 |
| Monitoring | 8 | 1 | 9 |
| CI/CD | 0 | 3 | 3 |
| Containers | 0 | 3 | 3 |
| Performance | 0 | 1 | 1 |
| **TOTAL** | **28** | **13** | **41** |

---

## ✅ SERVICIOS DETALLADOS

**Activos (28)**: VPC, IGW, NAT GW, Route 53, VPC Logs, EC2, ASG, Launch Template, Elastic IP, RDS, RDS Snapshots, S3, Security Groups, IAM Users, IAM Roles, IAM Policies, WAF, KMS, Secrets Mgr, CloudWatch Logs, CloudWatch Metrics, CloudWatch Alarms, CloudWatch Dashboard, CloudTrail, X-Ray, SNS, (ALB-Target Groups diseñados)

**Planificados (13)**: Client VPN, Network Firewall, ElastiCache Redis, GuardDuty, AWS Config, CodeDeploy, CodeBuild, Lambda, ECR, ECS, EKS, CloudFront, (GitHub Actions)

---

*Versión: 2.0 - COMPLETO CON TODOS LOS 41 SERVICIOS*  
*Última actualización: 15 de noviembre de 2025*  
*Proyecto: PCFactory Migration AWS - Capstone DuocUC 2025*
