variable "project_name" {
  type        = string
  description = "Nombre del proyecto"
}

variable "environment" {
  type        = string
  description = "Entorno (dev, prod, staging)"
}

variable "description" {
  type        = string
  default     = "KMS key para cifrado de datos"
  description = "Descripción de la clave KMS"
}

variable "deletion_window_in_days" {
  type        = number
  default     = 30
  description = "Ventana para eliminación (en días)"
}

variable "enable_key_rotation" {
  type        = bool
  default     = true
  description = "Habilitar rotación automática de clave"
}

variable "key_name" {
  type        = string
  description = "Nombre descriptivo para la clave KMS"
}

variable "alias_name" {
  type        = string
  description = "Nombre alias para la clave KMS"
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Tags adicionales para la clave KMS"
}
