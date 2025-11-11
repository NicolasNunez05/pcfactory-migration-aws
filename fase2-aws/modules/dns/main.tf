# =============================================================================
# MÓDULO: DNS - ROUTE 53 PUBLIC HOSTED ZONE
# =============================================================================
# Este módulo gestiona ÚNICAMENTE la zona PÚBLICA de Route 53 para acceso
# desde Internet. La zona privada (corp.local) se mantiene en módulo database.
#
# ESTADO ACTUAL: TODO COMENTADO
# Código listo para implementación futura cuando se compre dominio real
#
# INSTRUCCIONES PARA ACTIVAR:
# 1. Comprar dominio real (ej: pcfactory.com) en Route 53 o registrador externo
# 2. Verificar que ALB esté desplegado y funcionando
# 3. Descomentar TODOS los recursos de este archivo
# 4. Descomentar variables en variables.tf
# 5. Descomentar outputs en outputs.tf
# 6. En environments/dev/main.tf, descomentar el módulo "dns"
# 7. Ejecutar: terraform plan && terraform apply
# 8. Configurar Name Servers en registrador (si es externo)
# =============================================================================

# # =============================================================================
# # HOSTED ZONE PÚBLICA
# # =============================================================================
# resource "aws_route53_zone" "public" {
#   name    = var.domain
#   comment = "Zona DNS pública para ${var.project_name} - Accesible desde Internet"
#
#   tags = {
#     Name        = "${var.project_name}-public-zone"
#     Environment = var.environment
#     Project     = var.project_name
#     Type        = "PublicDNS"
#     ManagedBy   = "Terraform"
#   }
# }

# # =============================================================================
# # REGISTRO A (ALIAS) - APLICACIÓN PRINCIPAL
# # =============================================================================
# # Crea un alias desde app.tudominio.com hacia el DNS del ALB
# # Usa registro tipo ALIAS (sin costo de queries DNS) en lugar de CNAME
# # Permite acceso con nombre amigable en lugar del DNS largo del ALB
# # =============================================================================
# resource "aws_route53_record" "app" {
#   zone_id = aws_route53_zone.public.zone_id
#   name    = "app.${var.domain}"  # Ejemplo: app.pcfactory.com
#   type    = "A"
#
#   # ALIAS al ALB - NO genera cargos por queries DNS
#   alias {
#     name                   = var.alb_dns_name
#     zone_id                = var.alb_zone_id
#     evaluate_target_health = true  # Failover automático si ALB falla
#   }
# }

# # =============================================================================
# # REGISTRO APEX - DOMINIO RAÍZ (OPCIONAL)
# # =============================================================================
# # Permite acceder directamente con pcfactory.com (sin subdominios)
# # Redirige a app.pcfactory.com
# # =============================================================================
# resource "aws_route53_record" "apex" {
#   zone_id = aws_route53_zone.public.zone_id
#   name    = var.domain  # Ejemplo: pcfactory.com
#   type    = "A"
#
#   alias {
#     name                   = var.alb_dns_name
#     zone_id                = var.alb_zone_id
#     evaluate_target_health = true
#   }
# }

# # =============================================================================
# # REGISTRO CNAME - WWW (OPCIONAL)
# # =============================================================================
# # Redirige www.tudominio.com hacia app.tudominio.com
# # Usuario escribe www.pcfactory.com → Se resuelve a app.pcfactory.com
# # =============================================================================
# resource "aws_route53_record" "www" {
#   zone_id = aws_route53_zone.public.zone_id
#   name    = "www.${var.domain}"
#   type    = "CNAME"
#   ttl     = 300
#   records = [aws_route53_record.app.fqdn]
# }

# # =============================================================================
# # REGISTRO A (ALIAS) - API (OPCIONAL)
# # =============================================================================
# # Subdominio separado para endpoints de API REST
# # Útil si separas frontend (app.pcfactory.com) y backend (api.pcfactory.com)
# # =============================================================================
# resource "aws_route53_record" "api" {
#   zone_id = aws_route53_zone.public.zone_id
#   name    = "api.${var.domain}"
#   type    = "A"
#
#   alias {
#     name                   = var.alb_dns_name
#     zone_id                = var.alb_zone_id
#     evaluate_target_health = true
#   }
# }

# # =============================================================================
# # HEALTH CHECK - MONITOREO DEL ALB (OPCIONAL - AVANZADO)
# # =============================================================================
# # Monitorea continuamente la salud del ALB y envía alertas si falla
# # Permite failover automático a ALB secundario (si tienes multi-región)
# # Costo adicional: $0.50 USD/mes por health check
# # =============================================================================
# # resource "aws_route53_health_check" "alb" {
# #   fqdn              = var.alb_dns_name
# #   port              = 80
# #   type              = "HTTP"
# #   resource_path     = "/health"  # Endpoint de health check del ALB
# #   failure_threshold = 3           # Fallas consecutivas antes de marcar como unhealthy
# #   request_interval  = 30          # Intervalo de chequeo en segundos
# #
# #   tags = {
# #     Name = "${var.project_name}-alb-health-check"
# #   }
# # }

# # =============================================================================
# # REGISTRO TXT - VERIFICACIÓN DE DOMINIO (OPCIONAL)
# # =============================================================================
# # Útil para verificar propiedad del dominio con servicios externos
# # (Google Search Console, AWS Certificate Manager, etc.)
# # =============================================================================
# # resource "aws_route53_record" "txt_verification" {
# #   zone_id = aws_route53_zone.public.zone_id
# #   name    = var.domain
# #   type    = "TXT"
# #   ttl     = 300
# #   records = [
# #     "v=spf1 include:_spf.google.com ~all",  # Ejemplo SPF
# #     "pcfactory-verification=abc123xyz"       # Token verificación
# #   ]
# # }

# # =============================================================================
# # NOTAS Y CONSIDERACIONES IMPORTANTES
# # =============================================================================
# #
# # COSTOS ESTIMADOS (AWS US-EAST-1):
# # - Hosted Zone pública: $0.50 USD/mes
# # - Primeras 1,000,000,000 queries/mes: $0.40 por millón de queries
# # - Queries adicionales: $0.20 por millón
# # - Health checks: $0.50 USD/mes por check (opcional)
# # - Registro de dominio: $12-15 USD/año (si lo registras en Route 53)
# #
# # TIEMPOS DE PROPAGACIÓN DNS:
# # - Cambios internos (dentro de AWS): ~60 segundos
# # - Cambios globales (Internet): 24-48 horas típico (depende de TTL)
# # - Primera propagación: Puede tomar hasta 72 horas
# #
# # REQUISITOS PREVIOS:
# # 1. ALB desplegado y funcionando correctamente
# # 2. Outputs del módulo load-balancer disponibles:
# #    - alb_dns_name: DNS completo del ALB
# #    - alb_zone_id: Zone ID interno del ALB (diferente de Route 53 Zone ID)
# # 3. Dominio real comprado (registrador externo o Route 53)
# #
# # SEGURIDAD:
# # - Zona pública expone registros DNS a Internet (esto es correcto)
# # - El ALB controla el acceso real mediante Security Groups
# # - La zona privada (corp.local) en módulo database sigue independiente
# # - No exponer información sensible en registros TXT
# # - Configurar DNSSEC para mayor seguridad (opcional, costo adicional)
# #
# # DIFERENCIAS CLAVE:
# # - Zona PRIVADA (corp.local): Solo accesible desde VPC
# #   * Uso: Comunicación interna entre servicios (EC2 <-> RDS)
# #   * Ejemplo: db.corp.local -> Endpoint RDS
# #
# # - Zona PÚBLICA (pcfactory.com): Accesible desde Internet
# #   * Uso: Acceso de usuarios finales a la aplicación
# #   * Ejemplo: app.pcfactory.com -> ALB -> EC2 instancias
# #
# # MEJORES PRÁCTICAS:
# # - Usar registros ALIAS en lugar de CNAME para recursos AWS (sin costo queries)
# # - Configurar TTL bajo (300s) durante implementación inicial
# # - Aumentar TTL (3600s) una vez estable para reducir queries
# # - Implementar health checks para alta disponibilidad
# # - Documentar todos los registros DNS en este archivo
# #
# # =============================================================================
