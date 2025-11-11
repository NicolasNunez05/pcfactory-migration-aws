#!/bin/bash
# scripts/deploy-to-ec2.sh - Desplegar aplicación a instancias EC2

set -e

ENVIRONMENT="${1:-dev}"
AWS_REGION="${2:-us-east-1}"
DOCKER_IMAGE_NAME="${3:-pcfactory-app}"
DOCKER_TAG="${4:-latest}"

AWS_ACCOUNT_ID="787124622819"
ECR_REPOSITORY_URL="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${DOCKER_IMAGE_NAME}"

echo "╔════════════════════════════════════════╗"
echo "║  Deployando a EC2                      ║"
echo "║  Ambiente: $ENVIRONMENT               ║"
echo "║  Imagen: $DOCKER_IMAGE_NAME:$DOCKER_TAG ║"
echo "║  Region: $AWS_REGION                  ║"
echo "╚════════════════════════════════════════╝"
echo ""

# Obtener instancias EC2 con tag Environment
echo "[*] Buscando instancias EC2..."
INSTANCE_IDS=$(aws ec2 describe-instances \
    --filters "Name=tag:Environment,Values=$ENVIRONMENT" "Name=instance-state-name,Values=running" \
    --query "Reservations[*].Instances[*].InstanceId" \
    --output text \
    --region "$AWS_REGION")

if [ -z "$INSTANCE_IDS" ]; then
    echo "❌ No se encontraron instancias EC2 para ambiente: $ENVIRONMENT"
    exit 1
fi

echo "✅ Instancias encontradas:"
for instance_id in $INSTANCE_IDS; do
    echo "   - $instance_id"
done

echo ""
echo "[*] Generando script de deployment..."

# Crear script SSM que se ejecutará en instancias
DEPLOY_SCRIPT='#!/bin/bash
set -e

# Variables
ECR_REPOSITORY_URL="'$ECR_REPOSITORY_URL'"
DOCKER_IMAGE_NAME="'$DOCKER_IMAGE_NAME'"
DOCKER_TAG="'$DOCKER_TAG'"
AWS_REGION="'$AWS_REGION'"
CONTAINER_NAME="pcfactory-app"
CONTAINER_PORT=8080
HOST_PORT=8080

echo "[*] Script de deployment iniciado"
echo "    Imagen: $ECR_REPOSITORY_URL:$DOCKER_TAG"

# Login a ECR
echo "[*] Autenticando con ECR..."
aws ecr get-login-password --region $AWS_REGION | \
    docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com

# Detener contenedor anterior si existe
echo "[*] Deteniendo contenedor anterior..."
docker stop $CONTAINER_NAME || true
docker rm $CONTAINER_NAME || true

# Limpiar imágenes antiguas
docker rmi $ECR_REPOSITORY_URL:* || true

# Pull nueva imagen
echo "[*] Descargando imagen..."
docker pull $ECR_REPOSITORY_URL:$DOCKER_TAG

# Ejecutar nuevo contenedor
echo "[*] Iniciando nuevo contenedor..."
docker run -d \
    --name $CONTAINER_NAME \
    -p $HOST_PORT:$CONTAINER_PORT \
    -e ENVIRONMENT='\'$ENVIRONMENT\'' \
    -e AWS_REGION=$AWS_REGION \
    -v /var/log/pcfactory:/var/log/pcfactory \
    --restart unless-stopped \
    $ECR_REPOSITORY_URL:$DOCKER_TAG

echo "[*] Esperando a que inicie la aplicación..."
sleep 5

# Verificar salud
echo "[*] Verificando health check..."
if curl -f http://localhost:$HOST_PORT/health; then
    echo "✅ Aplicación iniciada correctamente"
else
    echo "❌ Health check falló"
    docker logs $CONTAINER_NAME
    exit 1
fi

echo "✅ Deployment completado"
'

# Ejecutar script en cada instancia usando SSM
echo "[*] Ejecutando deployment en instancias..."
for instance_id in $INSTANCE_IDS; do
    echo ""
    echo "   Desplegando en: $instance_id"
    
    COMMAND_ID=$(aws ssm send-command \
        --document-name "AWS-RunShellScript" \
        --parameters "commands=['$DEPLOY_SCRIPT']" \
        --instance-ids "$instance_id" \
        --region "$AWS_REGION" \
        --query "Command.CommandId" \
        --output text)
    
    echo "   Command ID: $COMMAND_ID"
    
    # Esperar a que complete
    aws ssm wait command-executed \
        --command-id "$COMMAND_ID" \
        --instance-id "$instance_id" \
        --region "$AWS_REGION"
    
    # Obtener resultado
    RESULT=$(aws ssm get-command-invocation \
        --command-id "$COMMAND_ID" \
        --instance-id "$instance_id" \
        --region "$AWS_REGION" \
        --query "Status" \
        --output text)
    
    if [ "$RESULT" == "Success" ]; then
        echo "   ✅ Deployment exitoso"
    else
        echo "   ❌ Deployment falló"
        aws ssm get-command-invocation \
            --command-id "$COMMAND_ID" \
            --instance-id "$instance_id" \
            --region "$AWS_REGION" \
            --query "StandardErrorContent" \
            --output text
        exit 1
    fi
done

echo ""
echo "╔════════════════════════════════════════╗"
echo "║  ✅ DEPLOYMENT COMPLETADO             ║"
echo "║  Ambiente: $ENVIRONMENT               ║"
echo "╚════════════════════════════════════════╝"

# Verificar que todas estén corriendo
echo ""
echo "[*] Estado final de instancias..."
aws ec2 describe-instances \
    --instance-ids $INSTANCE_IDS \
    --region "$AWS_REGION" \
    --query "Reservations[*].Instances[*].[InstanceId,InstanceType,State.Name,PublicIpAddress]" \
    --output table