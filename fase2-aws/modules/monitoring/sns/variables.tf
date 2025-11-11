variable "project_name" {
  description = "Nombre del proyecto"
  type        = string
}

variable "environment" {
  description = "Ambiente (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "email_endpoint" {
  description = "Email para recibir notificaciones de alarmas"
  type        = string
  validation {
    condition     = can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", var.email_endpoint))
    error_message = "Debe ser un email válido"
  }
}

variable "sms_endpoint" {
  description = "Número de teléfono para recibir SMS de alarmas críticas (formato: +56912345678)"
  type        = string
  validation {
    condition     = can(regex("^\\+[1-9]\\d{1,14}$", var.sms_endpoint))
    error_message = "Debe ser un número de teléfono en formato internacional (ej: +56981972292)"
  }
}

variable "enable_sms" {
  description = "Habilitar notificaciones SMS (puede tener costo)"
  type        = bool
  default     = true
}
