output "alb_sg_id" {
  description = "ID del Security Group del ALB"
  value       = aws_security_group.alb_sg.id
}

output "app_sg_id" {
  description = "ID del Security Group de App"
  value       = aws_security_group.app_sg.id
}

output "db_sg_id" {
  description = "ID del Security Group de DB"
  value       = aws_security_group.db_sg.id
}

output "nat_gateway_id" {
  description = "ID del NAT Gateway"
  value       = aws_nat_gateway.main.id
}