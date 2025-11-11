#!/bin/bash

echo "Iniciando proceso de migración PCFactory a AWS..."

# Copiar backup de base de datos al bucket S3
echo "Subiendo backup de base de datos a S3..."
aws s3 cp /local/backups/db-backup.sql s3://pcfactory-backups/db-backup.sql

# Inicializar Terraform
echo "Iniciando Terraform..."
cd terraform/
terraform init

# Aplicar infraestructura sin confirmación manual
echo "Aplicando infraestructura Terraform..."
terraform apply -auto-approve

echo "Proceso de migración completado exitosamente."