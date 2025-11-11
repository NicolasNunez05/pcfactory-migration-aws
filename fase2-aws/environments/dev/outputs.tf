output "vpc_id" {
  description = "VPC ID - Usada para proximas operaciones"
  value       = try(aws_vpc.main.id, "No encontrada")
}

output "vpc_cidr" {
  description = "CIDR de la VPC"
  value       = try(aws_vpc.main.cidr_block, "N/A")
}

output "environment_summary" {
  description = "Resumen del ambiente desplegado"
  value = {
    project_name = var.project_name
    environment  = var.environment
    region       = var.aws_region
    timestamp    = timestamp()
  }
}

# Salida para debugging
output "destroy_instruction" {
  description = "Instrucción para destruir"
  value       = "Ejecutar: ./scripts/tf-apply-destroy.sh ${var.environment} destroy"
}
