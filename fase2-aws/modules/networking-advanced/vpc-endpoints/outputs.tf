# =============================================================================
# OUTPUTS - VPC ENDPOINTS
# =============================================================================

output "s3_gateway_endpoint_id" {
  description = "ID del S3 Gateway Endpoint"
  value       = var.enable_s3_gateway ? aws_vpc_endpoint.s3[0].id : null
}

output "dynamodb_gateway_endpoint_id" {
  description = "ID del DynamoDB Gateway Endpoint"
  value       = var.enable_dynamodb_gateway ? aws_vpc_endpoint.dynamodb[0].id : null
}

output "interface_endpoints" {
  description = "Mapa de interface endpoints creados"
  value = {
    for k, v in aws_vpc_endpoint.interface : k => {
      id                  = v.id
      dns_entry           = v.dns_entry
      network_interface_ids = v.network_interface_ids
    }
  }
}

output "enabled_endpoints_count" {
  description = "Número de endpoints interface habilitados"
  value       = length(local.enabled_endpoints)
}

output "monthly_cost_estimate" {
  description = "Estimación de costo mensual ($0.01/hora por endpoint)"
  value       = "$${length(local.enabled_endpoints) * 0.01 * 24 * 30}"
}
