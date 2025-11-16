# PCFactory Migration - AWS con Terraform

**Proyecto de Migración de Infraestructura On-Premise a AWS**

![Status](https://img.shields.io/badge/Status-Active-brightgreen) ![Phase](https://img.shields.io/badge/Phase-2-blue) ![Terraform](https://img.shields.io/badge/Terraform-1.5%2B-623CE4)

---

## 📋 Tabla de Contenidos

- [Resumen Ejecutivo](#resumen-ejecutivo)
- [Arquitectura](#arquitectura)
- [Servicios AWS Utilizados](#servicios-aws-utilizados)
- [Tecnologías](#tecnologías)
- [Estructura del Proyecto](#estructura-del-proyecto)
- [Fases del Proyecto](#fases-del-proyecto)
- [Comenzar](#comenzar)
- [Despliegue](#despliegue)
- [Estructura de Red](#estructura-de-red)
- [Seguridad](#seguridad)
- [Monitoreo](#monitoreo)
- [Limitaciones Conocidas](#limitaciones-conocidas)
- [Contacto](#contacto)

---

## 📖 Resumen Ejecutivo

**PCFactory Migration** es un proyecto de capstone académico que simula y ejecuta la **migración completa de infraestructura on-premise a AWS** utilizando **Infrastructure as Code (Terraform)**.

El proyecto evoluciona PCFactory desde una infraestructura local simulada con Docker hacia una **arquitectura empresarial cloud-native en AWS**, demostrando:

✅ Migración segura de datos  
✅ Infraestructura como código escalable  
✅ Alta disponibilidad Multi-AZ  
✅ Seguridad perimetral granular  
✅ Automatización y best practices AWS  
✅ Monitoreo y logging completo  
✅ Despliegue automatizado con CI/CD  

---

## 🏗️ Arquitectura

### Diagrama de Alto Nivel

```
                          INTERNET
                            ↓
                    Internet Gateway (IGW)
                            ↓
            ┌───────────────────────────────┐
            │   PUBLIC SUBNETS (2 AZs)      │
            │  10.20.10.0/24 (us-east-1a)   │
            │  10.20.11.0/24 (us-east-1b)   │
            │                               │
            │  ├─ NAT Gateway (Elastic IP)  │
            │  └─ Application Load Balancer │
            │     (bloqueado por SQ limit)  │
            └───────────────────────────────┘
                            ↓
            ┌───────────────────────────────┐
            │  PRIVATE APP SUBNETS (2 AZs)  │
            │  10.20.20.0/24 (us-east-1a)   │
            │  10.20.21.0/24 (us-east-1b)   │
            │                               │
            │  ├─ EC2 Auto Scaling Group    │
            │  │  (Flask Application)       │
            │  │  - Min: 1, Max: 3          │
            │  │  - Instance: t2.micro      │
            │  └─ Security Group: App-SG    │
            └───────────────────────────────┘
                            ↓
            ┌───────────────────────────────┐
            │  PRIVATE DB SUBNETS (2 AZs)   │
            │  10.20.30.0/24 (us-east-1a)   │
            │  10.20.31.0/24 (us-east-1b)   │
            │                               │
            │  ├─ RDS PostgreSQL (Multi-AZ) │
            │  │  Instance: db.t3.micro     │
            │  │  Backups: Automáticos      │
            │  └─ Security Group: DB-SG     │
            └───────────────────────────────┘

SERVICIOS ADICIONALES:
├─ Route 53 (DNS privado corp.local)
├─ Route 53 (DNS público comentado)
├─ CloudWatch (Logs y Dashboards)
├─ SNS (Notificaciones)
├─ Client VPN (Acceso remoto)
├─ Network Firewall (Opcional)
├─ ECR (Container Registry)
├─ Systems Manager (Session Manager)
├─ KMS (Cifrado)
├─ Secrets Manager (Credenciales)
└─ S3 (Backend Terraform)
```

---

## 🛠️ Servicios AWS Utilizados

### FASE 2 - Infraestructura Cloud

#### 🔌 NETWORKING (5 servicios)

| Servicio | Función | Estado | Modulo |
|----------|---------|--------|--------|
| **VPC** | Red privada virtual 10.20.0.0/16 | ✅ Activo | networking |
| **Subnets** | 6 subnets (2 públicas, 2 app privadas, 2 db privadas) | ✅ Activo | networking |
| **Internet Gateway** | Conexión a Internet | ✅ Activo | networking |
| **NAT Gateway** | Salida a Internet desde privadas | ✅ Activo | security |
| **Route Tables** | Tablas de enrutamiento por función | ✅ Activo | networking |

#### 💻 COMPUTE (6 servicios)

| Servicio | Función | Estado | Modulo |
|----------|---------|--------|--------|
| **EC2 Instances** | Servidores aplicación (t2.micro) | ✅ Activo | compute |
| **Auto Scaling Group** | Escalado automático 1-3 instancias | ✅ Activo | compute |
| **Launch Template** | Plantilla para instancias | ✅ Activo | compute |
| **AMI** | Amazon Linux 2023 con Python 3.11 | ✅ Activo | compute |
| **Application Load Balancer** | ⚠️ Diseñado pero bloqueado por SQ | ❌ Limitación | load-balancer |
| **Target Groups** | Grupos de destino para ALB | ✅ Activo | load-balancer |

#### 🗄️ DATABASE (4 servicios)

| Servicio | Función | Estado | Modulo |
|----------|---------|--------|--------|
| **RDS PostgreSQL** | Base de datos principal (db.t3.micro) | ✅ Activo | database |
| **RDS Multi-AZ** | Alta disponibilidad (comentado en dev) | ✅ Implementado | database |
| **RDS Backups** | Backups automáticos 30 días | ✅ Activo | database |
| **Route 53 Private Zone** | DNS interno corp.local | ✅ Activo | database |

#### 🔐 SECURITY (8 servicios)

| Servicio | Función | Estado | Modulo |
|----------|---------|--------|--------|
| **Security Groups** | Firewall por capas (ALB, App, DB) | ✅ Activo | security |
| **Network ACLs** | ACLs adicionales (opcional) | ✅ Implementado | networking |
| **IAM Roles** | 3 roles: Admin, App, Terraform | ✅ Activo | security |
| **IAM Policies** | Políticas granulares por rol | ✅ Activo | security |
| **IAM Users** | 11 usuarios (Admin, App, Operacionales) | ✅ Activo | security |
| **IAM Groups** | 2 grupos de seguridad | ✅ Activo | security |
| **KMS Keys** | Cifrado de datos en reposo | ✅ Implementado | security |
| **Network Firewall** | Firewall AWS (opcional, costoso) | ⚠️ Comentado | network-firewall |

#### 🌐 CONECTIVIDAD (3 servicios)

| Servicio | Función | Estado | Modulo |
|----------|---------|--------|--------|
| **Client VPN** | Acceso remoto vpn.corp.local:443 | ⚠️ Preparado | client-vpn |
| **Systems Manager Session Manager** | Acceso sin SSH a instancias | ✅ Activo | security |
| **Route 53 Public** | DNS público pcfactory.com | ⚠️ Comentado | database |

#### 📊 MONITORING (4 servicios)

| Servicio | Función | Estado | Modulo |
|----------|---------|--------|--------|
| **CloudWatch Logs** | Logs de aplicación y sistema | ✅ Activo | (scripts) |
| **CloudWatch Dashboards** | Dashboards visuales | ✅ Preparado | (scripts) |
| **CloudWatch Alarms** | Alertas por métricas | ✅ Preparado | (scripts) |
| **SNS Topics** | Notificaciones por email | ✅ Preparado | (scripts) |

#### 📦 STORAGE (2 servicios)

| Servicio | Función | Estado | Modulo |
|----------|---------|--------|--------|
| **S3 Bucket** | Backend Terraform state | ✅ Activo | (global) |
| **S3 Lifecycle** | Archivado de backups RDS | ✅ Preparado | (scripts) |

#### 🔑 SECRETS & CREDENTIALS (1 servicio)

| Servicio | Función | Estado | Modulo |
|----------|---------|--------|--------|
| **Secrets Manager** | Rotación automática contraseñas | ✅ Preparado | (scripts) |

#### 🚀 CONTAINER & CI/CD (4 servicios)

| Servicio | Función | Estado | Modulo |
|----------|---------|--------|--------|
| **ECR** | Container registry privado | ✅ Preparado | (scripts) |
| **GitHub Actions** | CI/CD pipeline | ✅ Implementado | (.github/workflows) |
| **CodeDeploy** | Despliegue automatizado | ✅ Preparado | (scripts) |
| **CodeBuild** | Build automático | ✅ Preparado | (scripts) |

---

### TOTAL DE SERVICIOS AWS: 31+

| Categoría | Cantidad |
|-----------|----------|
| Servicios activos | 23 ✅ |
| Servicios preparados/comentados | 5 ⚠️ |
| Servicios bloqueados/limitados | 1 ❌ |
| Scripts de provisioning | 8 |
| Workflows CI/CD | 3 |

---

## 🛠️ Tecnologías

### Stack Principal

| Componente | Versión | Propósito |
|---|---|---|
| **Terraform** | 1.5+ | Infrastructure as Code |
| **AWS CLI** | 2.0+ | Interacción con AWS |
| **Python** | 3.9+ | Aplicación Flask |
| **PostgreSQL** | 15 | Base de datos |
| **Docker** | 20.0+ | Simulación on-premise (Fase 1) |
| **GitHub Actions** | Latest | CI/CD Pipeline |
| **OpenSSL** | 3.0+ | Certificados VPN |

---

## 📁 Estructura del Proyecto

```
pcfactory-migration-aws/
├── certificates/              # Certificados SSL/TLS para VPN
│   ├── server.key
│   ├── server.crt
│   ├── client-ca.crt
│   └── client[1-8].crt/key
│
├── config/                    # Configuraciones globales
│   ├── backend.conf           # Backend remoto S3 + DynamoDB
│   ├── providers.conf         # Versiones de providers
│   └── environments.conf       # Variables por entorno
│
├── docs/                      # Documentación técnica
│   ├── ARCHITECTURE.md        # Diagrama y explicación
│   ├── MIGRATION_PLAN.md      # Plan de migración
│   ├── SECURITY.md            # Políticas de seguridad
│   ├── ALB-LIMITACION.md      # Análisis limitación ALB
│   ├── ROUTE53PUBLICO_Limitacion.txt
│   └── ADR/                   # Architecture Decision Records
│
├── environments/              # Configuración por entorno
│   ├── dev/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── terraform.tfvars
│   ├── staging/
│   └── prod/
│
├── modules/                   # Módulos reutilizables
│   ├── networking/            # VPC, Subnets, Route Tables
│   ├── security/              # IAM, Security Groups, KMS
│   ├── database/              # RDS, Route 53 Private
│   ├── compute/               # EC2, ASG, Launch Templates
│   ├── load-balancer/         # ALB, Target Groups
│   ├── network-firewall/      # AWS Network Firewall
│   └── client-vpn/            # Client VPN Endpoint
│
├── scripts/                   # Scripts provisioning
│   ├── deploy-to-ec2.sh       # Despliegue a instancias
│   ├── setup-auto-healing.sh  # Auto-healing ASG
│   ├── setup-backup-rds.sh    # Backup automático
│   ├── setup-cloudwatch.sh    # Monitoreo
│   ├── setup-secrets-rotation.sh
│   ├── health-check.sh
│   ├── tf-apply-destroy.sh
│   ├── test.sh
│   ├── build.sh
│   └── push-ecr.sh
│
├── .github/workflows/         # CI/CD Workflows
│   ├── ci-cd-dev.yml
│   ├── terraform-plan.yml
│   ├── terraform-validate.yml
│   ├── blue-green-deploy.yml
│   └── deploy-to-ec2.sh
│
├── app/                       # Aplicación Flask
│   ├── app.py
│   ├── requirements.txt
│   └── tests/
│
└── README.md                  # Este archivo
```

---

## 📊 Fases del Proyecto

### Fase 1: Blueprint On-Premise ✅
**Docker Compose con simulación de infraestructura local**
- Nginx (Web Server)
- Flask (Application Server)
- PostgreSQL (Database)
- Samba4/Active Directory (Identity)
- DNS simulado

### Fase 2: Migración a AWS 🔄
**Infraestructura cloud-native con Terraform**
- ✅ VPC Multi-AZ 10.20.0.0/16
- ✅ 6 Subnets segmentadas
- ✅ RDS PostgreSQL con backups
- ✅ EC2 Auto Scaling Group
- ✅ Security Groups granulares
- ✅ IAM con 11 usuarios
- ✅ Route 53 DNS privado
- ⚠️ ALB (bloqueado por Service Quota)
- ✅ CloudWatch Monitoring
- ✅ CI/CD con GitHub Actions

### Fase 3: Automatización CI/CD 📋
**Pipeline Jenkins/GitHub Actions**
- Build automático
- Testing
- Deployment blue-green
- Integración con GitHub

### Fase 4: Modernización con Kubernetes 📋
**Orquestación con EKS**
- EKS Cluster
- Despliegue en pods
- Horizontal Pod Autoscaling

---

## 🚀 Comenzar

### Requisitos Previos

```bash
terraform version      # 1.5.0+
aws --version         # 2.13.0+
python --version      # 3.9+
git --version         # 2.40+

aws configure
aws sts get-caller-identity
```

### Instalación

```bash
# Clonar repositorio
git clone https://github.com/NicolasNunez05/pcfactory-migration-aws.git
cd pcfactory-migration-aws

# Crear backend S3
aws s3 mb s3://pcfactory-terraform-state-$(date +%s) --region us-east-1

# Crear tabla DynamoDB para locking
aws dynamodb create-table \
  --table-name pcfactory-terraform-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5

# Crear archivo de variables
cd environments/dev
cp terraform.tfvars.example terraform.tfvars
vim terraform.tfvars
```

---

## 🔧 Despliegue

```bash
cd environments/dev

# Inicializar
terraform init -backend-config=../../config/backend.conf

# Validar
terraform validate

# Planificar
terraform plan -out=tfplan

# Aplicar
terraform apply tfplan

# Ver outputs
terraform output -json
```

---

## 🌐 Estructura de Red

| VLAN On-Prem | Subnet AWS | CIDR | Capa | Función |
|---|---|---|---|---|
| DMZ (VLAN 40) | Public 1a/1b | 10.20.10-11/24 | Web | NAT, IGW |
| App (VLAN 30) | Private App | 10.20.20-21/24 | App | EC2 ASG |
| DB (VLAN 20) | Private DB | 10.20.30-31/24 | DB | RDS |
| Admin (VLAN 10) | - | - | Mgmt | Session Mgr |
| VPN (VLAN 50) | VPN Pool | 172.16.0.0/22 | Remote | Client VPN |

---

## 🔐 Seguridad

### Usuarios IAM (11 total)

**Administradores (3)**
- nicolas.nunez
- jose.catalan
- carla.reyes

**Usuarios Operacionales (8)**
- felipe.rojas, javiera.soto, matias.perez
- camila.gonzalez, diego.castro, valentina.diaz
- andres.silva, isidora.morales

### Security Groups

```
ALB-SG:       80/443 ← Internet
    ↓
App-SG:       8080 ← ALB, 22 ← Admin (SSH)
    ↓
DB-SG:        5432 ← App-SG only
```

### IAM Roles

- **Admin**: AdministratorAccess (proyecto)
- **App**: CloudWatch, SSM, S3, Secrets Manager
- **Terraform**: Permisos mínimos para provisioning

---

## 📊 Monitoreo

### CloudWatch

```bash
# Crear SNS Topic
aws sns create-topic --name pcfactory-alerts-dev

# Crear Log Groups
aws logs create-log-group --log-group-name /aws/ec2/pcfactory-dev

# Crear Dashboards
aws cloudwatch put-dashboard --dashboard-name pcfactory-dev
```

### Alarmas Configuradas

- EC2 CPU > 80% → Scale-up
- EC2 CPU < 20% → Scale-down
- RDS Conexiones > 80 → Notificar
- Errores en logs → SNS Alert

---

## ⚠️ Limitaciones Conocidas

### 1. Application Load Balancer (ALB)

**Estado**: ❌ Bloqueado por Service Quota  
**Error**: `OperationNotPermitted: This AWS account currently does not support creating load balancers`  
**Código**: modules/load-balancer/main.tf (completamente implementado)  
**Documentación**: ALB-LIMITACION.md  
**Solución**: Solicitar aumento de Service Quota a AWS Support

### 2. Network Firewall

**Estado**: ⚠️ Comentado (costoso $570/mes)  
**Ubicación**: modules/network-firewall/  
**Uso**: Descomentar solo para producción

### 3. Client VPN

**Estado**: ⚠️ Preparado, no permanente  
**Costo**: $108/mes mínimo  
**Requisitos**: Certificados TLS en certificates/

### 4. Route 53 Público

**Estado**: ⚠️ Comentado  
**Requisito**: Dominio pcfactory.com registrado  
**Costo**: $0.50/mes + queries

---

## 📞 Contacto

**Autor**: Nicolás Núñez Álvarez  
**Email**: nicolasnunezalvarez05@gmail.com  
**GitHub**: [@NicolasNunez05](https://github.com/NicolasNunez05)  
**Institución**: DuocUC  
**Programa**: Capstone - Cloud Architecture  

---

## 📝 Licencia

Proyecto académico. Distribuido bajo licencia MIT.

---

**Última actualización**: 15 de noviembre de 2025  
**Versión**: 2.1 (Fase 2 - Servicios Detallados)  
**Estado**: ✅ En producción (dev environment)  
**Repositorio**: https://github.com/NicolasNunez05/pcfactory-migration-aws
