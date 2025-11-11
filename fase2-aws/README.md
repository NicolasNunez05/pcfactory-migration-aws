# PCFactory - Migración AWS con Terraform

Migración de infraestructura on-premise a AWS utilizando Infrastructure as Code (IaC) con Terraform. Proyecto académico de Capstone (DuocUC) que implementa arquitectura Multi-AZ, Auto Scaling, alta disponibilidad y seguridad en capas.

---

## Badges

![Terraform](https://img.shields.io/badge/Terraform-v1.9+-623CE4?logo=terraform&logoColor=white)
![AWS](https://img.shields.io/badge/AWS-Cloud-FF9900?logo=amazon-aws&logoColor=white)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-316192?logo=postgresql&logoColor=white)
![Docker](https://img.shields.io/badge/Docker-2496ED?logo=docker&logoColor=white)
![License](https://img.shields.io/badge/License-Academic-blue)
![Status](https://img.shields.io/badge/Status-Completed-success)

---

## Tabla de Contenidos

- [Descripción](#descripción)
- [Arquitectura](#arquitectura)
- [Estructura del Proyecto](#estructura-del-proyecto)
- [Requisitos Previos](#requisitos-previos)
- [Instalación](#instalación)
- [Configuración](#configuración)
- [Despliegue](#despliegue)
- [Estrategia de Costos](#estrategia-de-costos)
- [Limitaciones Conocidas](#limitaciones-conocidas)
- [Documentación Adicional](#documentación-adicional)
- [Comandos Útiles](#comandos-útiles)
- [Troubleshooting](#troubleshooting)
- [Próximos Pasos](#próximos-pasos-fase-3)
- [Autor](#autor)

---

## Descripción

Este proyecto implementa una migración completa de la infraestructura on-premise de **PCFactory** (empresa de retail tecnológico) hacia AWS, utilizando Terraform como herramienta de Infrastructure as Code.

### Contexto Académico

**Institución**: DuocUC  
**Carrera**: Ingeniería en Conectividad y Redes  
**Proyecto**: Capstone 2025  
**Profesor Guía**: Lionel Pizarro

### Objetivos del Proyecto

- Migrar arquitectura de 3 capas (Web, App, DB) a AWS
- Implementar alta disponibilidad con distribución Multi-AZ
- Automatizar despliegue de infraestructura con Terraform
- Aplicar mejores prácticas de seguridad cloud
- Optimizar costos mediante estrategia dev/prod

### Componentes Principales

- **Networking**: VPC con subnets públicas y privadas Multi-AZ
- **Compute**: Auto Scaling Group con Launch Templates (Amazon Linux 2023)
- **Database**: RDS PostgreSQL 14+ con backups automatizados
- **Security**: Network Firewall AWS, Security Groups en capas, IAM RBAC
- **Connectivity**: Client VPN para acceso remoto seguro
- **Monitoring**: CloudWatch Logs para auditoría y compliance

---

## Arquitectura

### Diagrama de Alto Nivel
Internet
                             |
                      [Internet Gateway]
                             |
             +---------------+---------------+
             |                               |
     [Public Subnet 1a]              [Public Subnet 1b]
     - NAT Gateway                   - (Redundancia)
             |                               |
     +-------+-------+               +-------+-------+
     |               |               |               |

[Private App 1a] [Private DB 1a] [Private App 1b] [Private DB 1b]

    EC2 (ASG) - RDS Primary - EC2 (ASG) - RDS Standby

    Auto Scaling - PostgreSQL - Auto Scaling - (Multi-AZ)


### Componentes de Red

| Componente | CIDR | Zona | Descripción |
|------------|------|------|-------------|
| VPC | 10.20.0.0/16 | us-east-1 | Red virtual aislada |
| Public Subnet 1 | 10.20.10.0/24 | us-east-1a | NAT Gateway, IGW |
| Public Subnet 2 | 10.20.11.0/24 | us-east-1b | Redundancia |
| Private App 1 | 10.20.20.0/24 | us-east-1a | Instancias EC2 |
| Private App 2 | 10.20.21.0/24 | us-east-1b | Instancias EC2 |
| Private DB 1 | 10.20.30.0/24 | us-east-1a | RDS Primary |
| Private DB 2 | 10.20.31.0/24 | us-east-1b | RDS Standby |
| VPN CIDR | 172.16.0.0/22 | - | Client VPN pool |

---

## Estructura del Proyecto
pcfactory-migration-aws/
│
├── certificates/ # Certificados SSL/TLS para Client VPN
│ ├── server.crt
│ ├── server.key
│ ├── client-ca.crt
│ └── client[1-8].crt/key
│
├── config/ # Configuraciones globales
│ ├── backend.conf # S3 + DynamoDB state backend
│ └── providers.conf # AWS provider config
│
├── docs/ # Documentación del proyecto
│ ├── aws-architecture.md
│ ├── migration-plan.md
│ └── ALB-LIMITACION.md # Análisis de limitación ALB
│
├── environments/
│ ├── dev/ # Entorno de desarrollo
│ │ ├── main.tf # Orquestación de módulos
│ │ ├── variables.tf
│ │ ├── outputs.tf
│ │ └── terraform.tfvars # Variables específicas (gitignored)
│ │
│ ├── staging/ # Entorno de staging (preparado)
│ └── prod/ # Entorno de producción (preparado)
│
└── modules/ # Módulos reutilizables
├── networking/ # VPC, subnets, routing
├── security/ # Security Groups, IAM, NAT
├── compute/ # EC2, ASG, Launch Templates
├── database/ # RDS, Route53 private zone
├── load-balancer/ # ALB, Target Groups, Listeners
├── network-firewall/ # AWS Network Firewall
└── client-vpn/ # Client VPN Endpoint


---

## Requisitos Previos

### Software Requerido

- **Terraform**: v1.9 o superior
- **AWS CLI**: v2.x
- **Git**: Para control de versiones
- **Docker Desktop**: Para fase 1 (simulación on-premise)
- **OpenSSL**: Para generación de certificados VPN
- **VS Code**: Editor recomendado con extensión HashiCorp Terraform

### Cuenta AWS

- Cuenta AWS activa (ID utilizada: 787124622819)
- Credenciales IAM con permisos:
  - EC2, VPC, RDS
  - IAM (crear roles y policies)
  - CloudWatch Logs
  - Network Firewall (opcional)
  - Client VPN (opcional)

### Conocimientos

- Terraform básico (resources, modules, state)
- AWS fundamentals (VPC, EC2, RDS)
- Networking básico (CIDR, subnets, routing)

---

## Instalación

### 1. Clonar el repositorio

git clone https://github.com/NicolasNunez05/pcfactory-migration-aws.git
cd pcfactory-migration-aws


### 2. Instalar Terraform

**Windows (Chocolatey)**:
choco install terraform

**Linux/Mac (tfenv recomendado)**:
brew install tfenv
tfenv install 1.9.0
tfenv use 1.9.0

### 3. Configurar AWS CLI
aws configure


Ingresar:
- AWS Access Key ID
- AWS Secret Access Key
- Default region: `us-east-1`
- Output format: `json`

Verificar:
aws sts get-caller-identity


---

## Configuración

### 1. Crear archivo de variables

Copiar el template:
cd environments/dev
cp terraform.tfvars.example terraform.tfvars

Editar `terraform.tfvars`:
project_name = "pcfactory-migration"
aws_region = "us-east-1"
Network

vpc_cidr = "10.20.0.0/16"
Compute

instance_type = "t2.micro"
desired_capacity = 1 # Dev: 1, Prod: 2
min_size = 1
max_size = 3
Database

db_instance_class = "db.t3.micro"
db_name = "pcfactory_db"
db_username = "admin"
db_password = "TU_PASSWORD_SEGURO" # Cambiar obligatoriamente
multi_az = false # Dev: false, Prod: true
VPN (si se despliega)

vpn_cidr = "172.16.0.0/22"
server_certificate_arn = "arn:aws:acm:us-east-1:787124622819:certificate/..."
client_certificate_arn = "arn:aws:acm:us-east-1:787124622819:certificate/..."

### 2. Configurar Backend Remoto (Recomendado)

Crear bucket S3 y tabla DynamoDB:
Crear bucket para Terraform state

aws s3 mb s3://pcfactory-terraform-state-787124622819 --region us-east-1
Crear tabla DynamoDB para state locking

aws dynamodb create-table
--table-name pcfactory-terraform-locks
--attribute-definitions AttributeName=LockID,AttributeType=S
--key-schema AttributeName=LockID,KeyType=HASH
--billing-mode PAY_PER_REQUEST
--region us-east-1


Descomentar backend en `main.tf`:
terraform {
backend "s3" {
bucket = "pcfactory-terraform-state-787124622819"
key = "dev/terraform.tfstate"
region = "us-east-1"
dynamodb_table = "pcfactory-terraform-locks"
encrypt = true
}
}


---

## Despliegue

### 1. Inicializar Terraform
cd environments/dev
terraform init


Resultado esperado:
Terraform has been successfully initialized!


### 2. Validar configuración
terraform validate


### 3. Planificar despliegue
terraform plan


Revisar los recursos que se crearán (~40-50 recursos).

### 4. Aplicar infraestructura
terraform apply

Confirmar escribiendo `yes`.

**Tiempo estimado**: 15-20 minutos (principalmente RDS)

### 5. Verificar outputs
terraform output

Outputs disponibles:
- VPC ID
- Subnet IDs
- RDS Endpoint
- DNS interno (db.corp.local)
- Security Group IDs
- NAT Gateway ID

### 6. Conectarse a la infraestructura

**Opción 1: Session Manager (recomendado)**
Obtener Instance ID

aws ec2 describe-instances
--filters "Name=tag:Name,Values=pcfactory-migration-app-asg-instance"
--query "Reservations[].Instances[].InstanceId"
--output text
Conectar

aws ssm start-session --target i-xxxxxxxxx


**Opción 2: Client VPN (si está desplegado)**
- Descargar archivo `.ovpn` desde la consola
- Importar en AWS VPN Client
- Conectar

---

## Estrategia de Costos

### Entorno de Desarrollo (Actual)

Configuración optimizada para costos durante desarrollo iterativo:

| Recurso | Configuración | Costo Mensual Estimado |
|---------|--------------|------------------------|
| EC2 (1x t2.micro) | Free Tier 750h | $0.00 |
| RDS (db.t3.micro Single-AZ) | Free Tier 750h | $0.00 |
| NAT Gateway | 1x activo 24/7 | $32.40 |
| Data Transfer (estimado) | ~10 GB/mes | $0.90 |
| S3 (state backend) | < 5 GB | $0.00 |
| CloudWatch Logs (7 días) | ~1 GB | $0.50 |
| **TOTAL MENSUAL** | | **~$33.80** |

### Entorno de Producción (Proyectado)

Configuración enterprise-grade para alta disponibilidad:

| Recurso | Configuración | Costo Mensual Estimado |
|---------|--------------|------------------------|
| EC2 (2x t2.micro Multi-AZ) | Sin Free Tier | $17.28 |
| RDS (db.t3.micro Multi-AZ) | Sin Free Tier | $34.56 |
| NAT Gateway (2x Multi-AZ) | Opcional | $64.80 |
| ALB | Si disponible | $16.20 |
| Network Firewall | 2 AZs | $570.00 |
| Client VPN | 8 endpoints | $144.00 |
| Data Transfer | ~50 GB/mes | $4.50 |
| **TOTAL MENSUAL (completo)** | | **~$851.34** |
| **TOTAL SIN Firewall/VPN** | | **~$137.34** |

### Optimizaciones Implementadas

1. **Single-AZ en desarrollo**: RDS y 1 instancia EC2 reducen costos 50%
2. **Sin Network Firewall en dev**: Ahorro de $570/mes
3. **Sin Client VPN permanente**: Ahorro de $144/mes
4. **Free Tier maximizado**: EC2 y RDS en límites gratuitos
5. **CloudWatch Logs cortos**: 7 días retención vs 30 días producción

---

## Limitaciones Conocidas

### 1. Application Load Balancer No Desplegado

**Razón**: Limitación de Service Quota en la cuenta AWS utilizada.

**Error**:
OperationNotPermitted: This AWS account currently does not support creating load balancers.


**Estado del código**: Completamente implementado y funcional en `modules/load-balancer/`.

**Documentación completa**: Ver `docs/ALB-LIMITACION.md`

**Solución para producción**: Solicitar aumento de Service Quota a AWS Support.

---

### 2. Network Firewall (Desplegado pero costoso)

**Estado**: Desplegado y funcional.

**Costo**: ~$570/mes solo por el firewall.

**Recomendación**: Comentar módulo en desarrollo, activar solo para demos/producción.

---

### 3. Client VPN (Preparado pero no permanente)

**Estado**: Código completo, certificados generados.

**Costo**: ~$0.15/hora = $108/mes mínimo.

**Uso**: Activar solo cuando se requiera acceso remoto.

---

## Documentación Adicional

- **ALB-LIMITACION.md**: Análisis técnico de la limitación del Application Load Balancer
- **aws-architecture.md**: Diagrama detallado de la arquitectura
- **migration-plan.md**: Plan de migración fase por fase
- **DOCUMENTACION-Y-EVIDENCIA-FASE-2.docx**: Evidencias completas del proyecto (80+ capturas)

---

## Comandos Útiles

### Verificar estado
terraform show
terraform state list

### Ver recurso específico
terraform state show module.networking.aws_vpc.main

### Refrescar estado
terraform refresh

### Destruir infraestructura
terraform destroy

**Precaución**: Esto eliminará TODA la infraestructura. Confirmar con `yes`.

---

## Troubleshooting

### Error: State lock

Liberar lock manualmente (solo si estás seguro)

terraform force-unlock LOCK_ID

### Error: Credenciales AWS
Verificar configuración

aws configure list
Verificar identidad

aws sts get-caller-identity

### Error: Recursos ya existentes
Importar recurso existente
terraform import module.networking.aws_vpc.main vpc-xxxxxxxx


---

## Próximos Pasos (Fase 3)

- [ ] Implementar CI/CD con GitHub Actions
- [ ] Migrar aplicación Flask a contenedores (ECS/EKS)
- [ ] Implementar monitoreo avanzado con CloudWatch Dashboards
- [ ] Configurar alertas SNS por email
- [ ] Implementar backup automatizado de base de datos a S3
- [ ] Configurar WAF para protección web
- [ ] Implementar autenticación con Cognito

---

## Autor

**Nicolás Núñez Álvarez**  
Estudiante de Ingeniería en Conectividad y Redes  
DuocUC - Proyecto de Capstone 2025

**Contacto**:
- Email: nicolasnunezalvarez05@gmail.com
- GitHub: [@NicolasNunez05](https://github.com/NicolasNunez05)
- LinkedIn: [Nicolás Núñez Álvarez](https://www.linkedin.com/in/nicolás-núñez-álvarez-35ba661ba/)

**Equipo del Proyecto**:
- Nicolás Núñez (Cloud Architect)
- José Catalán (Administrador Cloud)
- Carla Reyes (Administradora Cloud)

---

## Licencia

Este proyecto es de uso académico para el Proyecto de Capstone de DuocUC 2025.  
Todos los derechos reservados.

---

## Agradecimientos

- **Prof. Lionel Pizarro** - Guía del proyecto Capstone
- **DuocUC** - Formación académica en Ingeniería en Conectividad y Redes
- **AWS** - Infraestructura cloud y documentación
- **HashiCorp** - Terraform y herramientas de IaC
- **Comunidad DevOps** - Best practices y recursos open-source

---

**Última actualización**: 28 de octubre de 2025  
**Versión**: 2.0 - Fase 2 Completada








