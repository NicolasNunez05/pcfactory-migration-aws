resource "aws_wafv2_web_acl" "this" {
  name        = "${var.project_name}-${var.environment}-waf"
  description = "Web ACL para proteccion de aplicacion"
  scope       = "REGIONAL" # Cambiar a CLOUDFRONT para distribución global
  default_action {
    allow {}
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.project_name}-${var.environment}-waf"
    sampled_requests_enabled   = true
  }

  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 1

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      sampled_requests_enabled   = true
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSManagedRulesCommonRuleSet"
    }
  }
}

# resource "aws_wafv2_web_acl_association" "alb" {
#   resource_arn = var.alb_arn
#   web_acl_arn  = aws_wafv2_web_acl.this.arn
# }