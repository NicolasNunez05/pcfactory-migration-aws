# SECURITY.md - VERSIÓN V2 COMPLETO CON TODOS LOS SERVICIOS

## 🔐 Política de Seguridad PCFactory AWS - COMPLETA

**Proyecto:** PCFactory Migration AWS  
**Estándar:** AWS Well-Architected Framework - Security Pillar  
**Servicios de Seguridad:** 7 activos + 2 planificados
**Clasificación:** Datos internos negocio

---

## 🛡️ SERVICIOS DE SEGURIDAD IMPLEMENTADOS (9 TOTALES)

### SERVICIOS ACTIVOS (7)

| # | Servicio | Función | Estado | Detalles |
|---|----------|---------|--------|----------|
| 1 | **Security Groups** (3) | Firewall L4 distribuido | ✅ | ALB-SG, App-SG, DB-SG |
| 2 | **IAM Users** (11) | Identity management | ✅ | 3 admin, 8 operators |
| 3 | **IAM Roles** (3) | Role-based access | ✅ | EC2-App, Terraform, CodeDeploy |
| 4 | **IAM Policies** (5) | Permission control | ✅ | Least privilege |
| 5 | **WAF** | Web App Firewall L7 | ✅ | XSS, SQLi, rate limit |
| 6 | **Secrets Manager** | Credential storage | ✅ | /rds/pcfactory/master |
| 7 | **KMS** | Encryption keys | ✅ | CMK for EBS, RDS, S3 |

### SERVICIOS PLANIFICADOS (2)

| # | Servicio | Función | Fase |
|---|----------|---------|------|
| 8 | **GuardDuty** | Threat detection | 2.5 |
| 9 | **AWS Config** | Compliance tracking | 3 |

---

## 🏗️ PRINCIPIOS DE SEGURIDAD CON SERVICIOS

### 1. Defense in Depth (7 CAPAS)

```
CAPA 1: Perimetral
├─ AWS Shield (included DDoS)
├─ WAF (XSS, SQLi, rate limit)
└─ Internet Gateway

CAPA 2: Red
├─ Network Firewall (IDS/IPS - planned)
├─ Security Groups (3: ALB, App, DB)
├─ VPC Flow Logs (traffic analysis)
└─ Route 53 (DNS security)

CAPA 3: Identidad
├─ IAM Users (11 total)
├─ IAM Roles (3 roles)
├─ IAM Policies (least privilege - 5)
└─ MFA (recommended)

CAPA 4: Acceso
├─ Session Manager (no SSH)
├─ Elastic IP (NAT)
└─ Subnets Privadas (EC2, DB isolated)

CAPA 5: Datos en Tránsito
├─ SSL/TLS (HTTPS 80/443)
├─ RDS SSL certificates
├─ VPN encryption (AES-256 - future)
└─ Secrets Manager (encrypted)

CAPA 6: Datos en Reposo
├─ KMS (Master keys)
├─ EBS encryption (EC2 volumes)
├─ RDS encryption (KMS)
├─ S3 encryption (Terraform state)
└─ Snapshots encryption

CAPA 7: Auditoría & Detección
├─ CloudTrail (API logging)
├─ CloudWatch Logs (app logs)
├─ VPC Flow Logs (network)
├─ GuardDuty (threat detection - planned)
└─ AWS Config (compliance - planned)
```

---

## 🔑 GESTIÓN DE IDENTIDAD & ACCESO (IAM)

### Usuarios IAM (11 Total)

#### Administradores (3)
```
Grupo: AdministradoresCloud
Política: AdministratorAccess

Usuarios:
1. nicolas.nunez (Creador proyecto)
2. jose.catalan (Administrator)
3. carla.reyes (Administrator)

Acceso: AWS Console + API
MFA: Recomendado (no implementado en dev)
```

#### Operacionales (8)
```
Grupo: UsuariosAplicacion
Política: ReadOnlyAccess

Usuarios:
1-8: Ventas, Asistencia, Operaciones
├─ Lectura: Describe, List, Get
├─ Monitoreo: CloudWatch Logs viewing
├─ Status: EC2/RDS health checking
└─ NO: Modificar, borrar, crear

Acceso: AWS Console (limitado)
MFA: Opcional
```

### Roles IAM (3)

#### EC2-App-Role
```
Servicio: EC2 instances
Permisos:
├─ CloudWatch Logs: PutLogEvents
├─ Secrets Manager: GetSecretValue
├─ Systems Manager: SSM access
├─ SSM Agent: UpdateInstanceInformation
└─ EC2 Messages: Complete access

Trust: ec2.amazonaws.com

Propósito: Acceso a Secrets, logging, SSM
```

#### Terraform-Execution-Role
```
Servicio: GitHub Actions (CI/CD future)
Permisos: (Restricted)
├─ EC2: Full (create, modify, delete)
├─ RDS: Full (create, modify, delete)
├─ VPC: Full (networks, subnets, routes)
├─ IAM: Limited (specific roles only)
├─ S3: Terraform bucket access
├─ DynamoDB: State locking
└─ CloudWatch: Alarms creation

Restricciones:
├─ NO IAM root access
├─ NO billing access
├─ NO Organizations access
└─ NO modification self

Propósito: IaC deployment automation
```

#### CodeDeploy-Role (Future)
```
Servicio: CodeDeploy (Phase 3)
Permisos:
├─ EC2: Describe, tag, list
├─ S3: GetObject (deployment bundles)
├─ SNS: Publish (notifications)
└─ CloudWatch: PutMetricAlarms

Propósito: Application deployment
```

### Políticas IAM (5)

1. **AdministratorAccess** - Full access (root alternative)
2. **ReadOnlyAccess** - Read-only operations
3. **EC2-App-Custom** - App-specific permissions
4. **Terraform-Custom** - IaC-specific permissions
5. **CodeDeploy-Custom** - Deployment permissions

---

## 🚧 NETWORK SECURITY - 8 SERVICIOS

### Security Groups (3)

#### ALB-SG
```
Inbound:
  • 80/TCP from 0.0.0.0/0 (HTTP)
  • 443/TCP from 0.0.0.0/0 (HTTPS - future)
  • ICMP from 0.0.0.0/0 (ping)

Outbound:
  • ALL (0.0.0.0/0)
```

#### App-SG
```
Inbound:
  • 8080/TCP from ALB-SG (Flask app)
  • 22/TCP from Admin IP (SSH debug - optional)
  • ICMP from 0.0.0.0/0

Outbound:
  • 5432/TCP to DB-SG (PostgreSQL)
  • 53/TCP to 0.0.0.0/0 (DNS)
  • 80,443/TCP to 0.0.0.0/0 (HTTP/HTTPS - updates)
  • NTP/123 to 0.0.0.0/0
```

#### DB-SG
```
Inbound:
  • 5432/TCP from App-SG only (PostgreSQL)

Outbound:
  • DENY all (completamente aislada)
```

### Red AWS Servicios

| Servicio | Función | Estado |
|----------|---------|--------|
| VPC | Network container | ✅ 10.20.0.0/16 |
| Subnets (6) | Segmentación | ✅ Public/Private/DB |
| IGW | Internet entry | ✅ Attached |
| NAT GW | Private salida | ✅ Elastic IP |
| Route 53 | DNS interno | ✅ corp.local |
| VPC Flow Logs | Traffic monitoring | ✅ CloudWatch |
| Network Firewall | Advanced (optional) | 📋 Planned |
| Client VPN | Remote access (future) | 📋 Planned |

---

## 🔐 ENCRIPTACIÓN DE DATOS (2 SERVICIOS)

### Encriptación en Tránsito

```
ALB ↔ Clientes:
├─ Protocol: TLS 1.2+
├─ Certificate: Self-signed (dev) → ACM (prod)
└─ Ciphers: ECDHE-RSA-AES128-GCM-SHA256

EC2 ↔ RDS:
├─ Connection: SSL/TLS required
├─ Managed by: RDS (automatic)
└─ Verification: Certificate pinning (optional)

VPN (Future):
├─ Protocol: TLS 1.2+ (OpenVPN)
├─ Cipher: AES-256-GCM
└─ Auth: Certificate + username/password
```

### Encriptación en Reposo (KMS)

```
EBS Volumes:
├─ Encryption: Enabled by default
├─ Key: AWS-managed (aws/ebs) or CMK
└─ Performance: No degradation

RDS PostgreSQL:
├─ Encryption: KMS (Customer Master Key)
├─ Key rotation: Annual
├─ Snapshots: Inherit encryption
└─ Backups: Encrypted automatically

S3 Buckets:
├─ Encryption: KMS default
├─ Versioning: Enabled (rollback)
├─ Access logs: CloudTrail
└─ Lifecycle: Archive to Glacier

Secrets Manager:
├─ Encryption: KMS automatic
├─ Rotation: 30 days (auto)
└─ Versions: Keep last 2
```

---

## 📊 AUDITORÍA & COMPLIANCE (3 SERVICIOS)

### CloudTrail (API Audit Logging)

```
Scope: All AWS APIs
Region: us-east-1
Storage: S3 (encrypted) + CloudWatch Logs
Retention: 90 days CW, 1 year S3

Events Logged:
├─ IAM (user login, API calls)
├─ EC2 (instance lifecycle)
├─ RDS (modifications)
├─ S3 (uploads, deletes)
├─ VPC (security group changes)
└─ Security (KMS key usage)

Digest: Enabled (integrity verification)
```

### CloudWatch Logs (Application Logging)

```
Log Groups (6):
1. /aws/ec2/flask (app logs)
2. /aws/ec2/system (system logs)
3. /aws/rds/postgresql (DB logs)
4. /aws/alb/access (ALB logs)
5. /aws/networkfirewall/alert (NFW - future)
6. /aws/networkfirewall/flow (NFW - future)

Retention: 7-365 days
Encryption: KMS
Queries: Searchable, filterable
Alarms: CloudWatch Alarms on patterns
```

### VPC Flow Logs (Network Monitoring)

```
Type: REJECT traffic (cost optimization)
Destination: CloudWatch Logs
Granularity: ENI-level
Fields: 14 (src IP, port, packets, bytes, action)
Retention: 30 days

Análisis:
├─ Detect port scans
├─ Identify anomalous traffic
├─ Forensic investigation
└─ Security validation
```

---

## 🚨 INCIDENT RESPONSE CON SERVICIOS

### Detección (GuardDuty - Future)

```
Monitoreo Continuo:
├─ VPC Flow Logs (network)
├─ CloudTrail (API calls)
├─ DNS logs (queries)
└─ S3 access logs

Análisis:
├─ Machine learning pattern detection
├─ Known malware signatures
├─ IP reputation lists
└─ Threat intelligence

Alertas:
├─ Medium severity → Email
├─ High severity → PagerDuty
└─ Critical → SMS + call
```

### Investigación

```
Herramientas:
├─ CloudTrail Events (últimas 90 días)
├─ VPC Flow Logs (últimas 30 días)
├─ CloudWatch Logs (application)
├─ X-Ray Traces (service map)
└─ EC2 System logs

Timeline:
├─ Cuando comenzó?
├─ Entry point?
├─ Scope del compromise?
└─ Data affected?
```

### Recuperación

```
Pasos:
1. Validar fix (reproduce vulnerability)
2. Patch/update (security group, policy)
3. Rebuild (if necessary)
4. Monitor (CloudWatch 24h)
5. Lessons learned session
```

---

## ✅ SERVICIOS DE SEGURIDAD RESUMEN

| Categoría | Activos | Planificados | Total |
|-----------|---------|--------------|-------|
| Identity & Access | 3 (IAM Roles) | 0 | 3 |
| Network | 4 (SG, VPC, IGW, Route53) | 2 (NFW, VPN) | 6 |
| Data Protection | 2 (KMS, Secrets) | 0 | 2 |
| Encryption | 2 (at-rest, in-transit) | 0 | 2 |
| Auditing | 3 (CloudTrail, Logs, VPC Logs) | 2 (GuardDuty, Config) | 5 |
| Compliance | 0 | 1 (AWS Config) | 1 |
| **TOTAL** | **14** | **5** | **19** |

---

## 📋 SECURITY CHECKLIST - ANTES DE PROD

**Identity:**
- [ ] MFA para admin accounts
- [ ] IAM roles creados
- [ ] Least privilege policies
- [ ] IAM users audited

**Network:**
- [ ] Security groups restrictivos
- [ ] Network Firewall (if needed)
- [ ] VPC isolated subnets
- [ ] Route 53 configured

**Data:**
- [ ] KMS keys created
- [ ] EBS encryption enabled
- [ ] RDS encryption enabled
- [ ] S3 encryption enabled

**Auditing:**
- [ ] CloudTrail active
- [ ] CloudWatch Logs enabled
- [ ] VPC Flow Logs enabled
- [ ] X-Ray sampling configured

**Compliance:**
- [ ] GuardDuty enabled
- [ ] AWS Config rules
- [ ] Security testing done
- [ ] Penetration test (optional)

**Incident Response:**
- [ ] Runbooks documented
- [ ] Escalation contacts
- [ ] Backup strategy
- [ ] Disaster recovery plan

---

**Documento:** SECURITY.md V2  
**Servicios Documentados:** 19 (14 activos + 5 planificados)  
**Última actualización:** 15 de noviembre de 2025  
**Proyecto:** PCFactory Migration AWS - Capstone DuocUC 2025
