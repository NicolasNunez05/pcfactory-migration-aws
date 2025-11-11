# ============================================================================
# ROUTE 53 PUBLIC HOSTED ZONE (PRODUCCIÓN)
# ============================================================================
# NOTA: Este módulo está comentado porque requiere un dominio registrado
# (ej: alb-pcfactory.com) que no está disponible en este proyecto académico.
# 
# Para habilitar en producción:
# 1. Registrar dominio en Route 53 o transferir desde otro registrador
# 2. Descomentar este bloque completo
# 3. Actualizar variable "domain_name" con tu dominio real
# 4. Cambiar nameservers del registrador a los NS de Route 53
# 5. Esperar propagación DNS (24-48 horas)
# ============================================================================

/*
# Public Hosted Zone
resource "aws_route53_zone" "public" {
  name    = var.domain_name
  comment = "Zona pública para resolución de dominio corporativo PCFactory"
  
  tags = {
    Name        = "${var.project_name}-public-zone"
    Environment = "production"
    Purpose     = "Public DNS resolution for ALB"
    ManagedBy   = "Terraform"
  }
}

# Registro A para ALB (apex domain)
resource "aws_route53_record" "alb_apex" {
  zone_id = aws_route53_zone.public.zone_id
  name    = var.domain_name  # alb-pcfactory.com
  type    = "A"
  
  # Alias hacia ALB (sin costo adicional vs CNAME)
  alias {
    name                   = var.alb_dns_name
    zone_id                = var.alb_zone_id
    evaluate_target_health = true
  }
}

# Registro A para subdominio www (opcional)
resource "aws_route53_record" "alb_www" {
  zone_id = aws_route53_zone.public.zone_id
  name    = "www.${var.domain_name}"  # www.alb-pcfactory.com
  type    = "A"
  
  alias {
    name                   = var.alb_dns_name
    zone_id                = var.alb_zone_id
    evaluate_target_health = true
  }
}

# Health Check para ALB (opcional pero recomendado)
resource "aws_route53_health_check" "alb" {
  fqdn              = var.alb_dns_name
  port              = 80
  type              = "HTTP"
  resource_path     = "/health"
  failure_threshold = 3
  request_interval  = 30
  
  tags = {
    Name = "${var.project_name}-alb-health-check"
  }
}
*/

# ============================================================================
# INSTRUCCIONES DE ACTIVACIÓN
# ============================================================================
# 
# PASO 1: REGISTRAR DOMINIO
# --------------------------
# Opción A: Dentro de AWS Route 53
#   - Costo: ~$12-15 USD/año (.com)
#   - AWS Console → Route 53 → Registered domains → Register domain
#   - Ventaja: Integración automática con Route 53
# 
# Opción B: Registrador externo (GoDaddy, Namecheap)
#   - Registrar dominio en el proveedor
#   - Obtener nameservers de Route 53 (output: route53_public_nameservers)
#   - Cambiar NS en el panel del registrador
# 
# PASO 2: DESCOMENTAR CÓDIGO
# ---------------------------
# 1. Remover /* y */ de este bloque (líneas 14 y 70)
# 2. Actualizar domain_name = "tu-dominio-real.com"
# 3. Verificar que module "load_balancer" está activo en main.tf
# 
# PASO 3: APLICAR CAMBIOS
# ------------------------
# $ cd environments/dev
# $ terraform init
# $ terraform plan  # Revisar que creará 3-4 recursos Route 53
# $ terraform apply
# 
# PASO 4: CONFIGURAR NAMESERVERS (si dominio externo)
# ----------------------------------------------------
# 1. Ejecutar: terraform output route53_public_nameservers
# 2. Copiar los 4 nameservers (ej: ns-123.awsdns-12.com)
# 3. Ir al panel del registrador (GoDaddy, Namecheap, etc.)
# 4. Buscar sección "Nameservers" o "DNS Management"
# 5. Cambiar de nameservers del registrador a los de Route 53
# 6. Guardar cambios
# 
# PASO 5: VALIDAR PROPAGACIÓN DNS
# --------------------------------
# $ nslookup alb-pcfactory.com
# $ dig alb-pcfactory.com
# $ curl http://alb-pcfactory.com/health
# 
# Tiempo de propagación: 10 minutos - 48 horas (promedio: 2-6 horas)
# 
# PASO 6: CONFIGURAR HTTPS (PRODUCCIÓN)
# --------------------------------------
# 1. Solicitar certificado SSL en AWS ACM (gratis):
#    resource "aws_acm_certificate" "alb" {
#      domain_name       = var.domain_name
#      validation_method = "DNS"
#    }
# 
# 2. Agregar listener HTTPS al ALB (puerto 443)
# 3. Redirigir HTTP → HTTPS automáticamente
# 
# ============================================================================
# COSTOS ESTIMADOS
# ============================================================================
# - Hosted Zone: $0.50 USD/mes
# - Queries (primeros 1B): $0.40 por millón
# - Health Checks: $0.50/mes por check
# - Dominio registrado: $12-15 USD/año
# 
# Costo mensual estimado (con dominio): ~$2.00 USD
# ============================================================================
