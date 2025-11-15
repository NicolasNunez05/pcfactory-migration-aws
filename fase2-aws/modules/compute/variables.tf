variable "project_name" {
  description = "Nombre del proyecto"
  type        = string
}


variable "vpc_id" {
  description = "ID de la VPC"
  type        = string
}


variable "vpc_cidr" {
  description = "CIDR block de la VPC"
  type        = string
  default     = "10.100.0.0/16"
}


variable "web_subnet_ids" {
  description = "IDs de las subredes públicas web"
  type        = list(string)
  default     = []
}


variable "app_subnet_ids" {
  description = "IDs de las subredes privadas de aplicacion"
  type        = list(string)
}


variable "app_security_group_id" {
  description = "ID del Security Group de App"
  type        = string
}


variable "db_endpoint" {
  description = "Endpoint de la base de datos RDS"
  type        = string
}


variable "db_name" {
  description = "Nombre de la base de datos"
  type        = string
}


variable "db_username" {
  description = "Usuario de la base de datos"
  type        = string
}


variable "db_password" {
  description = "Contrasena de la base de datos"
  type        = string
  sensitive   = true
}


variable "target_group_arn" {
  description = "ARN del Target Group del ALB"
  type        = string
  default     = ""
}


# ============================================================================
# SNS TOPICS PARA ALARMAS
# ============================================================================
variable "sns_topic_critical_arn" {
  description = "ARN del SNS topic para alarmas críticas"
  type        = string
}


variable "sns_topic_warning_arn" {
  description = "ARN del SNS topic para alarmas de advertencia"
  type        = string
}


variable "environment" {
  description = "Ambiente de despliegue"
  type        = string
  default     = "dev"
}


variable "enable_xray" {
  description = "Habilitar AWS X-Ray tracing"
  type        = bool
  default     = false
}


variable "xray_policy_arn" {
  description = "ARN de la IAM policy de X-Ray"
  type        = string
  default     = ""
}


variable "kms_key_arn" {
  description = "ARN de la clave KMS para usar en permisos"
  type        = string
}


# ============================================================================
# VARIABLES PARA JENKINS CI/CD (NUEVAS)
# ============================================================================

variable "jenkins_instance_type" {
  description = "Tipo de instancia para Jenkins"
  type        = string
  default     = "t3.small"
}

variable "jenkins_volume_size" {
  description = "Tamaño del volumen EBS para Jenkins (GB)"
  type        = number
  default     = 50
}

variable "enable_jenkins" {
  description = "Habilitar despliegue de Jenkins"
  type        = bool
  default     = true
}

variable "jenkins_admin_user" {
  description = "Usuario administrativo de Jenkins"
  type        = string
  default     = "admin"
}

variable "jenkins_admin_password" {
  description = "Contraseña del usuario administrativo de Jenkins"
  type        = string
  sensitive   = true
  default     = "pcfactory123"
}

variable "docker_socket_mount" {
  description = "Montar el socket de Docker en Jenkins"
  type        = bool
  default     = true
}

variable "jenkins_docker_image" {
  description = "Imagen Docker para Jenkins"
  type        = string
  default     = "jenkins/jenkins:lts"
}

variable "jenkins_agents_port" {
  description = "Puerto para Jenkins Agents"
  type        = number
  default     = 50000
}

variable "jenkins_ui_port" {
  description = "Puerto para la UI de Jenkins"
  type        = number
  default     = 8080
}

variable "jenkins_disable_security_init" {
  description = "Deshabilitar seguridad en primer acceso (SOLO DESARROLLO)"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags adicionales para todos los recursos"
  type        = map(string)
  default = {
    Fase      = "Fase3"
    Componente = "CI/CD"
    Version   = "1.0"
  }
}
