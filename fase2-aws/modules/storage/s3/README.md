# Módulo S3 Storage - PCFactory Migration AWS

Módulo Terraform para gestionar buckets S3 con configuración profesional empresarial.

## Características

### Seguridad
- Cifrado SSE-KMS en todos los buckets
- Block Public Access habilitado
- Bucket policies restrictivas
- Logging de acceso S3

### Buckets Configurados

#### 1. Backups Bucket
- **Propósito**: Almacenar backups de EC2, RDS y snapshots
- **Versionado**: Habilitado (90 días de retención)
- **Lifecycle**: STANDARD → STANDARD_IA → GLACIER_IR → DEEP_ARCHIVE
- **MFA Delete**: Opcional (configuración manual requerida)

#### 2. Logs Bucket
- **Propósito**: Almacenar logs de aplicación, CloudWatch y VPC Flow Logs
- **Versionado**: Deshabilitado (no necesario para logs)
- **Lifecycle**: STANDARD → STANDARD_IA → Eliminar (90 días)
- **Recibe**: S3 Access Logs de otros buckets

#### 3. Artifacts Bucket
- **Propósito**: Almacenar artefactos CI/CD, builds y releases
- **Versionado**: Habilitado (60 días de retención)
- **Lifecycle**: STANDARD → STANDARD_IA → Eliminar (180 días)

## Uso



module "s3_storage" {
source = "../../modules/storage/s3"

project_name = var.project_name
environment = var.environment
kms_key_id = module.kms.key_arn
Habilitar buckets

enable_backups_bucket = true
enable_logs_bucket = true
enable_artifacts_bucket = true
Configuración de lifecycle (opcional - usa defaults)

backups_standard_days = 30
backups_ia_days = 90
backups_glacier_days = 365

logs_standard_days = 30
logs_expiration_days = 90

artifacts_standard_days = 60
artifacts_ia_days = 180

tags = {
Team = "DevOps"
}
}


## Outputs Disponibles

- `backups_bucket_arn` - ARN del bucket de backups
- `logs_bucket_arn` - ARN del bucket de logs
- `artifacts_bucket_arn` - ARN del bucket de artifacts
- `all_bucket_arns` - Lista de todos los ARNs

## Mejores Prácticas Implementadas

1. Separación de buckets por función
2. Versionado selectivo según propósito
3. Lifecycle policies optimizadas para costos
4. Cifrado KMS para cumplimiento
5. Logging de acceso habilitado
6. Block Public Access en todos los buckets
7. Limpieza automática de uploads incompletos

## Variables Principales

| Variable | Tipo | Default | Descripción |
|----------|------|---------|-------------|
| `project_name` | string | - | Nombre del proyecto |
| `environment` | string | - | Ambiente (dev, staging, prod) |
| `kms_key_id` | string | - | ARN de clave KMS para cifrado |
| `enable_backups_bucket` | bool | true | Habilitar bucket de backups |
| `enable_logs_bucket` | bool | true | Habilitar bucket de logs |
| `enable_artifacts_bucket` | bool | true | Habilitar bucket de artifacts |

## Estructura de Archivos

modules/storage/s3/
├── main.tf # Recursos principales
├── variables.tf # Definición de variables
├── outputs.tf # Outputs del módulo
└── README.md # Documentación


## Lifecycle Policies Detalladas

### Backups Bucket
- 0-30 días: STANDARD
- 31-90 días: STANDARD_IA
- 91-365 días: GLACIER_IR
- 365+ días: DEEP_ARCHIVE
- Versiones no actuales: 90 días retención

### Logs Bucket
- 0-30 días: STANDARD
- 31-90 días: STANDARD_IA
- 90+ días: Eliminación

### Artifacts Bucket
- 0-60 días: STANDARD
- 61-180 días: STANDARD_IA
- 180+ días: Eliminación
- Versiones no actuales: 60 días retención

## Notas de Implementación

**Cifrado**: Todos los buckets utilizan cifrado SSE-KMS con la clave proporcionada.

**Block Public Access**: Habilitado por defecto en todos los buckets para cumplir con estándares de seguridad empresarial.

**Logging**: Los buckets de backups y artifacts envían logs de acceso al bucket de logs.

**MFA Delete**: Puede habilitarse para el bucket de backups, pero requiere configuración manual post-deployment.

## Autor

**Nicolás Núñez Álvarez**  
Proyecto: PCFactory Migration AWS - Capstone DuocUC 2025  
Email: nicolasnunezalvarez05@gmail.com  
Última actualización: 09 de noviembre de 2025
