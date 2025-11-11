variable "vpc_id" {
  description = "ID de la VPC"
  type        = string
}

variable "project_name" {
  description = "Nombre del proyecto"
  type        = string
}

variable "public_subnet_ids" {
  description = "IDs de las subredes públicas"
  type        = list(string)
}