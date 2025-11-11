output "alb_arn" {
  description = "ARN del Application Load Balancer"
  value       = aws_lb.main.arn
}

output "alb_dns_name" {
  description = "DNS name del ALB"
  value       = aws_lb.main.dns_name
}

output "alb_zone_id" {
  description = "Zone ID del ALB (para Route 53 alias)"
  value       = aws_lb.main.zone_id
}

output "target_group_arn" {
  description = "ARN del Target Group"
  value       = aws_lb_target_group.app.arn
}

# NUEVOS OUTPUTS PARA WAF
output "waf_web_acl_id" {
  description = "ID del WAF Web ACL"
  value       = aws_wafv2_web_acl.alb_waf.id
}

output "waf_web_acl_arn" {
  description = "ARN del WAF Web ACL"
  value       = aws_wafv2_web_acl.alb_waf.arn
}

output "waf_web_acl_capacity" {
  description = "Capacidad usada por el WAF Web ACL"
  value       = aws_wafv2_web_acl.alb_waf.capacity
}
