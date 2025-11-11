# =============================================================================
# OUTPUTS - MÓDULO DNS
# =============================================================================
# Todos los outputs comentados hasta activar el módulo
# =============================================================================

# output "zone_id" {
#   description = "ID de la zona pública Route 53"
#   value       = try(aws_route53_zone.public.zone_id, "")
# }

# output "zone_name" {
#   description = "Nombre de la zona (dominio)"
#   value       = try(aws_route53_zone.public.name, "")
# }

# output "zone_name_servers" {
#   description = "Name servers para configurar en registrador externo (GoDaddy, etc.)"
#   value       = try(aws_route53_zone.public.name_servers, [])
#   
#   # IMPORTANTE: Copiar estos 4 name servers a tu registrador de dominio
#   # Ejemplo de output:
#   # [
#   #   "ns-1234.awsdns-12.org",
#   #   "ns-5678.awsdns-34.com",
#   #   "ns-9012.awsdns-56.net",
#   #   "ns-3456.awsdns-78.co.uk"
#   # ]
# }

# output "app_fqdn" {
#   description = "FQDN completo de la aplicación principal"
#   value       = try(aws_route53_record.app.fqdn, "")
#   # Ejemplo: app.pcfactory.com
# }

# output "apex_fqdn" {
#   description = "FQDN del dominio raíz (apex)"
#   value       = try(aws_route53_record.apex.fqdn, "")
#   # Ejemplo: pcfactory.com
# }

# output "www_fqdn" {
#   description = "FQDN de WWW"
#   value       = try(aws_route53_record.www.fqdn, "")
#   # Ejemplo: www.pcfactory.com
# }

# output "api_fqdn" {
#   description = "FQDN de API"
#   value       = try(aws_route53_record.api.fqdn, "")
#   # Ejemplo: api.pcfactory.com
# }

# # output "health_check_id" {
# #   description = "ID del health check del ALB"
# #   value       = try(aws_route53_health_check.alb.id, "")
# # }

# # EJEMPLO DE USO DE OUTPUTS:
# # Después de terraform apply, ejecutar:
# # terraform output zone_name_servers
# # Copiar los 4 name servers y configurarlos en tu registrador
