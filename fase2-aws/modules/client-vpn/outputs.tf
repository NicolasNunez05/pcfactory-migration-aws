output "vpn_endpoint_id" {
  description = "ID del Client VPN Endpoint"
  value       = aws_ec2_client_vpn_endpoint.main.id
}

output "vpn_dns_name" {
  description = "DNS del Client VPN Endpoint"
  value       = aws_ec2_client_vpn_endpoint.main.dns_name
}

output "vpn_endpoint_arn" {
  description = "ARN del Client VPN Endpoint"
  value       = aws_ec2_client_vpn_endpoint.main.arn
}


# ============================================================================
# OUTPUTS - CLOUDWATCH LOGS
# ============================================================================

output "vpn_log_group_name" {
  description = "Nombre del log group de Client VPN"
  value       = aws_cloudwatch_log_group.vpn_logs.name
}

output "vpn_log_group_arn" {
  description = "ARN del log group de Client VPN"
  value       = aws_cloudwatch_log_group.vpn_logs.arn
}