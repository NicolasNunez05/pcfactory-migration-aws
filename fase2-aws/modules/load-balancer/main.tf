# =============================================================================
# APPLICATION LOAD BALANCER + AWS WAF - PCFACTORY MIGRATION
# =============================================================================

# ========================================
# APPLICATION LOAD BALANCER
# ========================================
resource "aws_lb" "main" {
  name               = "${var.project_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.alb_sg_id]
  subnets            = var.public_subnets

  enable_deletion_protection = false

  tags = {
    Name = "${var.project_name}-alb"
  }
}


# ========================================
# TARGET GROUP
# ========================================
resource "aws_lb_target_group" "app" {
  name     = "${var.project_name}-app-tg"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    path                = "/health"
    matcher             = "200"
  }

  deregistration_delay = 30

  tags = {
    Name = "${var.project_name}-app-tg"
  }
}


# ========================================
# LISTENER HTTP
# ========================================
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}


# =============================================================================
# AWS WAF - WEB APPLICATION FIREWALL
# =============================================================================
# PROPÓSITO: Proteger ALB contra DDoS, bots, SQL injection, XSS
# COSTO ESTIMADO: ~$5-10 USD/mes (depende del tráfico)
# BENEFICIO: Bloquea ataques antes de que lleguen a tus instancias EC2

resource "aws_wafv2_web_acl" "alb_waf" {
  name  = "${var.project_name}-alb-waf"
  scope = "REGIONAL"  # REGIONAL para ALB, CLOUDFRONT usa GLOBAL

  # Acción por defecto: permitir todo el tráfico
  # Las reglas específicas bloquearán tráfico malicioso
  default_action {
    allow {}
  }

  # =========================================================================
  # REGLA 1: Rate Limiting (Anti-DDoS básico)
  # =========================================================================
  # ¿Por qué? Prevenir que una sola IP haga miles de requests
  # Límite: 2000 requests cada 5 minutos por IP de origen
  # Acción: Bloquear con HTTP 429 Too Many Requests
  rule {
    name     = "RateLimitRule"
    priority = 1

    action {
      block {
        custom_response {
          response_code = 429  # HTTP 429 Too Many Requests
        }
      }
    }

    statement {
      rate_based_statement {
        limit              = 2000  # Requests por 5 minutos
        aggregate_key_type = "IP"  # Contar por IP de origen
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.project_name}-rate-limit"
      sampled_requests_enabled   = true  # Ver requests bloqueados en Console
    }
  }

  # =========================================================================
  # REGLA 2: AWS Managed Rules - Core Rule Set
  # =========================================================================
  # ¿Por qué? Reglas gestionadas por AWS actualizadas automáticamente
  # Detecta y bloquea:
  # - SQL injection (UNION SELECT, OR 1=1, etc.)
  # - XSS (Cross-Site Scripting)
  # - Path traversal (../ attacks)
  # - Command injection
  # - Otros ataques OWASP Top 10
  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 2

    override_action {
      none {}  # Aplicar acción definida en managed rule set (block)
    }

    statement {
      managed_rule_group_statement {
        vendor_name = "AWS"
        name        = "AWSManagedRulesCommonRuleSet"
        
        # Opcional: Excluir reglas específicas si causan falsos positivos
        # excluded_rule {
        #   name = "SizeRestrictions_BODY"
        # }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.project_name}-aws-common-rules"
      sampled_requests_enabled   = true
    }
  }

  # =========================================================================
  # REGLA 3: AWS Managed Rules - Known Bad Inputs
  # =========================================================================
  # ¿Por qué? Bloquea patrones conocidos de exploit kits y botnets
  # Ejemplos: malware signatures, command injection patterns
  rule {
    name     = "AWSManagedRulesKnownBadInputsRuleSet"
    priority = 3

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        vendor_name = "AWS"
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.project_name}-known-bad-inputs"
      sampled_requests_enabled   = true
    }
  }

  # =========================================================================
  # REGLA 4: AWS Managed Rules - Anonymous IP List
  # =========================================================================
  # ¿Por qué? Bloquea requests desde:
  # - VPNs comerciales (NordVPN, ExpressVPN)
  # - Proxies anónimos
  # - Nodos Tor
  # - Cloud providers usados para ataques (hosting providers maliciosos)
  #
  # NOTA: COMENTADA por defecto porque puede bloquear usuarios legítimos con VPN
  # Descomentar solo si tu app NO debe ser accesible desde VPNs/proxies
  # rule {
  #   name     = "AWSManagedRulesAnonymousIpList"
  #   priority = 4
  #
  #   override_action {
  #     none {}
  #   }
  #
  #   statement {
  #     managed_rule_group_statement {
  #       vendor_name = "AWS"
  #       name        = "AWSManagedRulesAnonymousIpList"
  #     }
  #   }
  #
  #   visibility_config {
  #     cloudwatch_metrics_enabled = true
  #     metric_name                = "${var.project_name}-anonymous-ip"
  #     sampled_requests_enabled   = true
  #   }
  # }

  # =========================================================================
  # REGLA 5: Geo-Blocking (OPCIONAL)
  # =========================================================================
  # ¿Por qué? Si tu aplicación solo opera en países específicos,
  # bloquear otros países reduce superficie de ataque
  #
  # Ejemplo: Solo permitir Chile, Argentina, Perú, Brasil
  # NOTA: COMENTADA por defecto, descomentar si necesitas geo-blocking
  # rule {
  #   name     = "GeoBlockingRule"
  #   priority = 5
  #
  #   action {
  #     block {
  #       custom_response {
  #         response_code = 403
  #       }
  #     }
  #   }
  #
  #   statement {
  #     not_statement {
  #       statement {
  #         geo_match_statement {
  #           country_codes = ["CL", "AR", "PE", "BR"]  # Solo Sudamérica
  #         }
  #       }
  #     }
  #   }
  #
  #   visibility_config {
  #     cloudwatch_metrics_enabled = true
  #     metric_name                = "${var.project_name}-geo-blocking"
  #     sampled_requests_enabled   = true
  #   }
  # }

  # Configuración de visibilidad general del WAF
  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.project_name}-waf"
    sampled_requests_enabled   = true
  }

  tags = {
    Name = "${var.project_name}-alb-waf"
  }
}


# =============================================================================
# ASOCIAR WAF CON ALB
# =============================================================================
# Conecta el Web ACL con el Application Load Balancer
# Todo el tráfico al ALB pasa primero por WAF
resource "aws_wafv2_web_acl_association" "alb" {
  resource_arn = aws_lb.main.arn
  web_acl_arn  = aws_wafv2_web_acl.alb_waf.arn
}

# ============================================================================
# CLOUDWATCH LOGS - LOGS LOCALES DE ALB
# ============================================================================
# NOTA: Este bloque está listo para cuando descomentar el ALB

# Log Group para access logs del ALB
resource "aws_cloudwatch_log_group" "alb_access" {
  name              = "/aws/alb/${var.project_name}/access"
  retention_in_days = 7
  
  tags = {
    Name   = "${var.project_name}-alb-access-logs"
    Module = "load-balancer"
    Type   = "Local"
  }
}

# IMPORTANTE: ALB access logs normalmente van a S3, no CloudWatch
# Para habilitar logs de ALB a S3, descomentar este bloque:
# resource "aws_s3_bucket" "alb_logs" {
#   bucket = "${var.project_name}-alb-logs-${data.aws_caller_identity.current.account_id}"
#   
#   tags = {
#     Name = "${var.project_name}-alb-logs"
#   }
# }
# 
# resource "aws_s3_bucket_policy" "alb_logs" {
#   bucket = aws_s3_bucket.alb_logs.id
#   policy = data.aws_iam_policy_document.alb_logs.json
# }
# 
# data "aws_iam_policy_document" "alb_logs" {
#   statement {
#     principals {
#       type        = "Service"
#       identifiers = ["elasticloadbalancing.amazonaws.com"]
#     }
#     actions   = ["s3:PutObject"]
#     resources = ["${aws_s3_bucket.alb_logs.arn}/*"]
#   }
# }
