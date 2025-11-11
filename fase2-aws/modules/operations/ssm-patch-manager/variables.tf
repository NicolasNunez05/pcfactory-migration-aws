variable "project_name" {
  type        = string
  description = "Nombre del proyecto"
}

variable "environment" {
  type        = string
  description = "Entorno (dev, prod)"
}

variable "instance_ids" {
  type        = list(string)
  description = "Lista de IDs de instancias EC2 para aplicar parches"
}

variable "schedule_expression" {
  type        = string
  default     = "cron(0 2 ? * SUN *)"
  description = "Expresión cron para ejecución de parches"
}

variable "patch_document_content" {
  type        = any
  description = "Contenido JSON del documento de parcheo SSM"
  default = {
    "schemaVersion": "0.3",
    "description": "Patch Windows and Linux instances",
    "mainSteps": [
      {
        "action": "aws:runCommand",
        "name": "runPatchBaseline",
        "inputs": {
          "DocumentName": "AWS-RunPatchBaseline",
          "Parameters": {
            "Operation": ["Install"],
            "RebootOption": ["IfNeeded"]
          }
        }
      }
    ]
  }
}
