# Módulo ElastiCache Redis - PCFactory Migration AWS

Módulo Terraform para desplegar ElastiCache Redis con Cluster Mode Enabled, configuración profesional empresarial.

## Características

### Arquitectura
- **Cluster Mode Enabled**: Escalabilidad horizontal con múltiples shards
- **Multi-AZ**: Alta disponibilidad con failover automático
- **Réplicas**: Mínimo 2 réplicas por shard para redundancia
- **Redis 7.1**: Última versión con características avanzadas

### Seguridad
- Cifrado en tránsito (TLS)
- Cifrado en reposo con KMS
- Autenticación Redis AUTH + IAM
- Security groups configurables
- VPC privada aislada

### Alta Disponibilidad
- Failover automático habilitado
- Multi-AZ distribution
- Réplicas de lectura para distribución de carga
- Backups automáticos diarios

### Monitoreo y Mantenimiento
- CloudWatch Logs integrado
- Snapshots automáticos con retención configurable
- Ventana de mantenimiento programada
- Notificaciones SNS opcionales

## Configuración Recomendada

### Para Desarrollo

node_type = "cache.t4g.micro"
num_node_groups = 2
replicas_per_node_group = 1

### Para Producción

node_type = "cache.m7g.large"
num_node_groups = 3
replicas_per_node_group = 2

## Uso

module "elasticache_redis" {
source = "../../modules/cache/elasticache-redis"

project_name = "pcfactory-migration"
environment = "dev"
Red

vpc_id = module.networking.vpc_id
private_subnet_ids = module.networking.private_subnets_app
allowed_security_group_ids = [module.compute.app_security_group_id]
Configuración del cluster

node_type = "cache.t4g.micro"
num_node_groups = 3
replicas_per_node_group = 2
redis_version = "7.1"
Alta disponibilidad

multi_az_enabled = true
automatic_failover_enabled = true
Seguridad

transit_encryption_enabled = true
at_rest_encryption_enabled = true
kms_key_id = module.monitoring.kms_key_arn
auth_token_enabled = true
auth_token = var.redis_auth_token
Backups

snapshot_retention_limit = 7
snapshot_window = "03:00-05:00"
Mantenimiento

maintenance_window = "sun:02:00-sun:04:00"

tags = {
Team = "DevOps"
}
}

## Endpoints

### Cluster Mode Enabled
Usa el **Configuration Endpoint** para conectarte:

configuration_endpoint_address = "pcfactory-dev-redis.xxxxx.clustercfg.use1.cache.amazonaws.com"
port = 6379

### Conexión desde aplicación

import redis

redis_client = redis.RedisCluster(
host='configuration_endpoint_address',
port=6379,
password='your-auth-token',
ssl=True,
decode_responses=True
)

## Variables Principales

| Variable | Tipo | Default | Descripción |
|----------|------|---------|-------------|
| `project_name` | string | - | Nombre del proyecto |
| `environment` | string | - | Ambiente (dev, staging, prod) |
| `vpc_id` | string | - | ID de la VPC |
| `private_subnet_ids` | list(string) | - | IDs de subnets privadas |
| `node_type` | string | cache.t4g.micro | Tipo de instancia |
| `num_node_groups` | number | 3 | Número de shards |
| `replicas_per_node_group` | number | 2 | Réplicas por shard |
| `redis_version` | string | 7.1 | Versión de Redis |

## Outputs

- `configuration_endpoint_address` - Endpoint principal para Cluster Mode
- `replication_group_id` - ID del replication group
- `security_group_id` - ID del security group
- `port` - Puerto de Redis
- `total_nodes` - Número total de nodos

## Cálculo de Nodos Totales

Total Nodes = num_node_groups × (replicas_per_node_group + 1)

Ejemplo: 3 shards × (2 réplicas + 1 primario) = 9 nodos

## Mejores Prácticas Implementadas

1. Cluster Mode Enabled para escalabilidad horizontal
2. Multi-AZ para alta disponibilidad
3. Cifrado TLS + KMS para seguridad
4. Autenticación AUTH + IAM
5. Backups automáticos diarios
6. Ventanas de mantenimiento programadas
7. Security groups restrictivos
8. Parameter group optimizado