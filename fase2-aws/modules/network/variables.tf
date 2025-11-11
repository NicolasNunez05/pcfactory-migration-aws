variable "vpc_cidr" {
  description = "CIDR block para la VPC"
  type        = string
  default     = "10.20.0.0/16"
}

variable "availability_zones" {
  description = "Zonas de disponibilidad"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "project_name" {
  description = "Nombre del proyecto"
  type        = string
}

variable "nat_gateway_id" {
  description = "NAT Gateway ID for private subnets"
  type        = string
}