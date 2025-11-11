#!/bin/bash
set -e

ENVIRONMENT="${1:-dev}"
ACTION="${2:-apply}"
REGION="us-east-1"
ACCOUNT_ID="787124622819"

echo "=========================================="
echo "Terraform $ACTION para ambiente: $ENVIRONMENT"
echo "=========================================="

# Cambiar a directorio correcto
cd "$(dirname "$0")/../environments/$ENVIRONMENT" || exit 1

# Verificar credenciales AWS
echo "[*] Verificando credenciales AWS..."
CALLER_IDENTITY=$(aws sts get-caller-identity --region "$REGION" 2>/dev/null)
if [ $? -ne 0 ]; then
    echo "Error: Credenciales AWS no válidas"
    exit 1
fi

ACTUAL_ACCOUNT=$(echo "$CALLER_IDENTITY" | jq -r '.Account')
if [ "$ACTUAL_ACCOUNT" != "$ACCOUNT_ID" ]; then
    echo "Advertencia: Cuenta diferente. Esperado: $ACCOUNT_ID, Actual: $ACTUAL_ACCOUNT"
fi

echo "Credenciales verificadas - Cuenta: $ACTUAL_ACCOUNT"

# APLICAR CAMBIOS
if [ "$ACTION" = "apply" ]; then
    echo ""
    echo "[*] Inicializando Terraform..."
    terraform init -upgrade
    
    echo ""
    echo "[*] Validando configuración..."
    terraform validate
    
    echo ""
    echo "[*] Generando plan..."
    terraform plan -out=tfplan
    
    echo ""
    echo "ADVERTENCIA: Se aplicarán los cambios planeados"
    read -p "¿Deseas continuar? (si/no): " CONFIRM
    if [ "$CONFIRM" != "si" ]; then
        echo "Operación cancelada"
        rm -f tfplan
        exit 0
    fi
    
    echo ""
    echo "[*] Aplicando cambios..."
    terraform apply tfplan
    rm -f tfplan
    
    echo ""
    echo "Aplicación completada"
    echo ""
    echo "[*] Extrayendo VPC ID creada..."
    
    VPC_ID=$(terraform output -raw vpc_id 2>/dev/null || echo "")
    if [ -z "$VPC_ID" ]; then
        echo "No se encontró VPC ID en outputs"
    else
        echo "VPC ID extraída: $VPC_ID"
        echo "   (Será usada en próximo terraform destroy)"
    fi
    
    echo ""
    echo "[*] Exportando outputs a archivo..."
    terraform output -json > outputs.json
    echo "Outputs guardados en: outputs.json"

# DESTRUIR INFRAESTRUCTURA
elif [ "$ACTION" = "destroy" ]; then
    echo ""
    echo "ADVERTENCIA: Esto eliminará TODA la infraestructura en $ENVIRONMENT"
    read -p "¿Estás seguro? Escribe 'SI, DESTRUIR' para confirmar: " DESTROY_CONFIRM
    
    if [ "$DESTROY_CONFIRM" != "SI, DESTRUIR" ]; then
        echo "Destrucción cancelada"
        exit 0
    fi
    
    echo ""
    echo "[*] Extrayendo recursos antes de destruir..."
    
    # Guardar IDs de recursos importantes
    terraform output -json > outputs-backup-$(date +%Y%m%d_%H%M%S).json
    echo "Backup de outputs creado"
    
    echo ""
    echo "[*] Ejecutando terraform destroy..."
    terraform destroy -auto-approve
    
    echo ""
    echo "[*] Limpiando archivos locales..."
    rm -f tfplan terraform.tfstate.backup
    
    echo ""
    echo "Destrucción completada"
    echo "   Verificar que No hay recursos huérfanos en AWS Console"

else
    echo "Acción no reconocida: $ACTION"
    echo "Uso: $0 [dev|prod|staging] [apply|destroy]"
    exit 1
fi

echo ""
echo "=========================================="
echo "Operación finalizada: $(date)"
echo "=========================================="
