output "vpc_id" {
  description = "ID de la VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr_block" {
  description = "Bloque CIDR IPv4 de la VPC"
  value       = aws_vpc.main.cidr_block
}

output "vpc_ipv6_cidr_block" {
  description = "Bloque CIDR IPv6 de la VPC"
  value       = aws_vpc.main.ipv6_cidr_block
}

output "public_subnet_ids" {
  description = "IDs de las subnets públicas"
  value       = aws_subnet.public[*].id
}

output "public_subnet_ipv6_cidr_blocks" {
  description = "Bloques CIDR IPv6 de las subnets públicas"
  value       = aws_subnet.public[*].ipv6_cidr_block
}

output "private_app_subnet_ids" {
  description = "IDs de las subnets privadas de aplicación"
  value       = aws_subnet.private_app[*].id
}

output "private_app_subnet_ipv6_cidr_blocks" {
  description = "Bloques CIDR IPv6 de las subnets privadas de aplicación"
  value       = aws_subnet.private_app[*].ipv6_cidr_block
}

output "private_db_subnet_ids" {
  description = "IDs de las subnets privadas de base de datos"
  value       = aws_subnet.private_db[*].id
}

output "private_db_subnet_ipv6_cidr_blocks" {
  description = "Bloques CIDR IPv6 de las subnets privadas de base de datos"
  value       = aws_subnet.private_db[*].ipv6_cidr_block
}

output "igw_id" {
  description = "ID del Internet Gateway"
  value       = aws_internet_gateway.main.id
}

output "eigw_id" {
  description = "ID del Egress-Only Internet Gateway"
  value       = aws_egress_only_internet_gateway.main.id
}
