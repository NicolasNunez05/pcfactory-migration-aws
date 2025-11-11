output "firewall_id" {
  description = "ID del Network Firewall"
  value       = aws_networkfirewall_firewall.main.id
}

output "firewall_arn" {
  description = "ARN del Network Firewall"
  value       = aws_networkfirewall_firewall.main.arn
}

output "firewall_status" {
  description = "Status del firewall"
  value       = aws_networkfirewall_firewall.main.firewall_status
}

output "firewall_name" {
  description = "Nombre del Network Firewall"
  value       = aws_networkfirewall_firewall.main.name
}


# ============================================================================
# OUTPUTS - CLOUDWATCH LOGS
# ============================================================================

output "firewall_flow_log_group_name" {
  description = "Nombre del log group de flow logs del firewall"
  value       = aws_cloudwatch_log_group.flow.name
}

output "firewall_alert_log_group_name" {
  description = "Nombre del log group de alertas del firewall"
  value       = aws_cloudwatch_log_group.alert.name
}

output "firewall_flow_log_group_arn" {
  description = "ARN del log group de flow logs"
  value       = aws_cloudwatch_log_group.flow.arn
}

output "firewall_alert_log_group_arn" {
  description = "ARN del log group de alertas"
  value       = aws_cloudwatch_log_group.alert.arn
}
