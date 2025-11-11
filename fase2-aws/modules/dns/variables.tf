# =============================================================================
# VARIABLES - MÓDULO DNS
# =============================================================================
# Todas las variables comentadas hasta activar el módulo
# =============================================================================

# variable "project_name" {
#   description = "Nombre del proyecto (usado en tags)"
#   type        = string
#   default     = "pcfactory-migration"
# }

# variable "environment" {
#   description = "Ambiente de despliegue (dev, staging, prod)"
#   type        = string
#   default     = "production"
# }

# variable "domain" {
#   description = "Dominio público para Route 53 (ej: pcfactory.com)"
#   type        = string
#   default     = "pcfactory.com"
#   
#   validation {
#     condition     = can(regex("^[a-z0-9][a-z0-9-]{1,61}[a-z0-9]\\.[a-z]{2,}$", var.domain))
#     error_message = "El dominio debe ser válido (ej: pcfactory.com)"
#   }
# }

# variable "alb_dns_name" {
#   description = "DNS name del ALB (obtener desde módulo load-balancer)"
#   type        = string
#   default     = ""
#   
#   # Ejemplo: pcfactory-alb-123456789.us-east-1.elb.amazonaws.com
# }

# variable "alb_zone_id" {
#   description = "Zone ID del ALB para crear alias en Route 53"
#   type        = string
#   default     = ""
#   
#   # Nota: Este es el Zone ID INTERNO del ALB proporcionado por AWS
#   # Es diferente del Zone ID de la hosted zone de Route 53
#   # Ejemplo: Z35SXDOTRQ7X7K (us-east-1)
# }

# variable "enable_health_check" {
#   description = "Habilitar health check del ALB (costo adicional: $0.50/mes)"
#   type        = bool
#   default     = false
# }

# variable "health_check_path" {
#   description = "Ruta para health check del ALB"
#   type        = string
#   default     = "/health"
# }

# variable "ttl_short" {
#   description = "TTL corto para cambios frecuentes (segundos)"
#   type        = number
#   default     = 300  # 5 minutos
# }

# variable "ttl_long" {
#   description = "TTL largo para registros estables (segundos)"
#   type        = number
#   default     = 3600  # 1 hora
# }
