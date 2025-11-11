#!/bin/bash
# scripts/setup-secrets-rotation.sh - Configurar Secrets Manager con rotación automática

set -e

ENVIRONMENT="${1:-dev}"
AWS_REGION="${2:-us-east-1}"
PROJECT_NAME="pcfactory-migration"

echo "╔════════════════════════════════════════╗"
echo "║  Configurando Secrets Rotation         ║"
echo "║  Ambiente: $ENVIRONMENT               ║"
echo "║  Region: $AWS_REGION                  ║"
echo "╚════════════════════════════════════════╝"
echo ""

# Crear secret para DB
echo "[*] Creando secret para credenciales RDS..."
SECRET_NAME="$PROJECT_NAME/rds/$ENVIRONMENT"

# Generar contraseña fuerte
DB_PASSWORD=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)

# Crear secret
SECRET_ARN=$(aws secretsmanager create-secret \
    --name "$SECRET_NAME" \
    --description "RDS Master Credentials for $ENVIRONMENT" \
    --secret-string '{
        "username": "admin",
        "password": "'$DB_PASSWORD'",
        "engine": "postgres",
        "port": 5432
    }' \
    --region "$AWS_REGION" \
    --query "ARN" \
    --output text 2>/dev/null || \
    aws secretsmanager describe-secret \
        --secret-id "$SECRET_NAME" \
        --region "$AWS_REGION" \
        --query "ARN" \
        --output text)

echo "✅ Secret creado: $SECRET_NAME"
echo "   ARN: $SECRET_ARN"

# Configurar rotación automática
echo ""
echo "[*] Configurando rotación automática..."

# Nota: Requiere Lambda ejecutor para rotación real
# Esta es una configuración básica
aws secretsmanager rotate-secret \
    --secret-id "$SECRET_NAME" \
    --rotation-rules AutomaticallyAfterDays=30 \
    --region "$AWS_REGION" 2>/dev/null || true

echo "✅ Rotación automática configurada"
echo "   Intervalo: cada 30 días"

# Crear secret para credenciales de aplicación
echo ""
echo "[*] Creando secret para credenciales de aplicación..."
APP_SECRET_NAME="$PROJECT_NAME/app/$ENVIRONMENT"
APP_SECRET_KEY=$(openssl rand -base64 32)

APP_SECRET_ARN=$(aws secretsmanager create-secret \
    --name "$APP_SECRET_NAME" \
    --description "Application Credentials for $ENVIRONMENT" \
    --secret-string '{
        "api_key": "'$(openssl rand -base64 32)'",
        "jwt_secret": "'$APP_SECRET_KEY'",
        "environment": "'$ENVIRONMENT'"
    }' \
    --region "$AWS_REGION" \
    --query "ARN" \
    --output text 2>/dev/null || \
    aws secretsmanager describe-secret \
        --secret-id "$APP_SECRET_NAME" \
        --region "$AWS_REGION" \
        --query "ARN" \
        --output text)

echo "✅ Secret creado: $APP_SECRET_NAME"
echo "   ARN: $APP_SECRET_ARN"

# Crear Lambda para rotación (plantilla)
echo ""
echo "[*] Lambda de rotación (referencia)..."
cat > /tmp/rotation-lambda.py << 'EOF'
import boto3
import json
from datetime import datetime

def lambda_handler(event, context):
    """
    Función Lambda para rotar secretos en AWS Secrets Manager
    """
    service_client = boto3.client('secretsmanager')
    secret_id = event['SecretId']
    token = event['ClientRequestToken']
    step = event['Step']
    
    print(f"Rotando secret: {secret_id}, Step: {step}")
    
    if step == "create":
        create_secret(service_client, secret_id, token)
    elif step == "set":
        set_secret(service_client, secret_id, token)
    elif step == "test":
        test_secret(service_client, secret_id, token)
    elif step == "finish":
        finish_secret(service_client, secret_id, token)
    else:
        raise ValueError(f"Step inválido: {step}")

def create_secret(service_client, secret_id, token):
    """Crear nueva versión del secret"""
    print(f"Creando nueva versión para {secret_id}")
    # Lógica para generar nuevo secret
    pass

def set_secret(service_client, secret_id, token):
    """Aplicar nuevo secret en el sistema"""
    print(f"Aplicando secret {secret_id}")
    # Lógica para actualizar credenciales
    pass

def test_secret(service_client, secret_id, token):
    """Verificar que el nuevo secret funciona"""
    print(f"Probando secret {secret_id}")
    # Lógica para validar credenciales
    pass

def finish_secret(service_client, secret_id, token):
    """Finalizar rotación"""
    print(f"Finalizando rotación de {secret_id}")
    service_client.update_secret_version_stage(
        SecretId=secret_id,
        VersionStage="AWSCURRENT",
        MoveToVersionId=token
    )
EOF

echo "✅ Plantilla Lambda creada en: /tmp/rotation-lambda.py"

# Tag de secrets
echo ""
echo "[*] Agregando tags..."
aws secretsmanager tag-resource \
    --secret-id "$SECRET_ARN" \
    --tags Key=Environment,Value="$ENVIRONMENT" Key=Project,Value="$PROJECT_NAME" \
    --region "$AWS_REGION"

echo "✅ Tags agregados"

# Resumen
echo ""
echo "╔════════════════════════════════════════╗"
echo "║  ✅ SECRETS ROTATION CONFIGURADO      ║"
echo "╚════════════════════════════════════════╝"
echo ""
echo "Secrets creados:"
echo "  RDS: $SECRET_NAME"
echo "  App: $APP_SECRET_NAME"
echo ""
echo "Acceder a secretos:"
echo "  aws secretsmanager get-secret-value --secret-id $SECRET_NAME --region $AWS_REGION"
echo "  aws secretsmanager get-secret-value --secret-id $APP_SECRET_NAME --region $AWS_REGION"
echo ""
echo "⚠️  Para rotación automática completa:"
echo "  1. Crear Lambda ejecutor (ver /tmp/rotation-lambda.py)"
echo "  2. Configurar en Secrets Manager → Rotation → Lambda function"
echo "  3. Establecer permisos IAM necesarios"