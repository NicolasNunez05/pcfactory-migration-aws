#!/bin/bash
# scripts/deploy-to-ec2-dynamic.sh - Deploy automático a EC2 (sin IDs hardcodeados)

set -e

ENVIRONMENT="${1:-dev}"
AWS_REGION="${2:-us-east-1}"
PROJECT_NAME="pcfactory-migration"
ECR_URL="787124622819.dkr.ecr.${AWS_REGION}.amazonaws.com/${PROJECT_NAME}-app"

echo "╔════════════════════════════════════════╗"
echo "║  Desplegando a EC2 (Dinámico)          ║"
echo "║  Ambiente: $ENVIRONMENT               ║"
echo "║  Region: $AWS_REGION                  ║"
echo "╚════════════════════════════════════════╝"
echo ""

# 1. Encontrar Auto Scaling Group dinámicamente
echo "[*] Buscando Auto Scaling Group..."
ASG_NAME=$(aws autoscaling describe-auto-scaling-groups \
    --region "$AWS_REGION" \
    --query "AutoScalingGroups[?Tags[?Key=='Name' && Value like '*asg*']].AutoScalingGroupName" \
    --output text | head -1)

if [ -z "$ASG_NAME" ]; then
    echo "❌ No se encontró ASG"
    exit 1
fi
echo "✅ ASG: $ASG_NAME"

# 2. Encontrar instancias en el ASG
echo ""
echo "[*] Encontrando instancias..."
INSTANCES=$(aws autoscaling describe-auto-scaling-groups \
    --auto-scaling-group-names "$ASG_NAME" \
    --region "$AWS_REGION" \
    --query "AutoScalingGroups[0].Instances[*].InstanceId" \
    --output text)

if [ -z "$INSTANCES" ]; then
    echo "❌ No hay instancias en el ASG"
    exit 1
fi

echo "✅ Instancias encontradas:"
for INSTANCE_ID in $INSTANCES; do
    echo "   - $INSTANCE_ID"
done

# 3. Obtener detalles de instancias
echo ""
echo "[*] Obteniendo información de instancias..."
INSTANCE_INFO=$(aws ec2 describe-instances \
    --instance-ids $INSTANCES \
    --region "$AWS_REGION" \
    --query "Reservations[*].Instances[*].[InstanceId,PrivateIpAddress,Tags[?Key=='Name'].Value|[0]]" \
    --output text)

echo "✅ Información:"
echo "$INSTANCE_INFO" | while read INSTANCE_ID PRIVATE_IP NAME; do
    echo "   Instance: $INSTANCE_ID | IP: $PRIVATE_IP | Name: $NAME"
done

# 4. Obtener RDS endpoint
echo ""
echo "[*] Buscando RDS database..."
RDS_ENDPOINT=$(aws rds describe-db-instances \
    --region "$AWS_REGION" \
    --query "DBInstances[0].Endpoint.Address" \
    --output text)

echo "✅ RDS: $RDS_ENDPOINT"

# 5. Obtener VPC ID
echo ""
echo "[*] Buscando VPC..."
VPC_ID=$(aws ec2 describe-vpcs \
    --filters "Name=tag:Name,Values=*pcfactory*" \
    --region "$AWS_REGION" \
    --query "Vpcs[0].VpcId" \
    --output text)

echo "✅ VPC: $VPC_ID"

# 6. Generar script de deployment
echo ""
echo "[*] Generando script de deployment..."
cat > /tmp/deploy.sh << 'DEPLOY_SCRIPT'
#!/bin/bash
# Script que se ejecuta en EC2 para hacer pull de imagen y correr contenedor

docker login -u AWS -p $(aws ecr get-login-password --region us-east-1) \
  787124622819.dkr.ecr.us-east-1.amazonaws.com

docker pull $ECR_URL:latest

docker stop pcfactory-app || true
docker rm pcfactory-app || true

docker run -d \
  --name pcfactory-app \
  -p 8080:8080 \
  -e ENVIRONMENT=$ENVIRONMENT \
  -e DB_HOST=$DB_HOST \
  -e LOG_GROUP=$LOG_GROUP \
  --restart always \
  $ECR_URL:latest

echo "✅ Container started"
DEPLOY_SCRIPT

echo "✅ Script generado"

# 7. Usar SSM para ejecutar en instancias
echo ""
echo "[*] Ejecutando deployment en instancias..."
for INSTANCE_ID in $INSTANCES; do
    echo "   Deployando en $INSTANCE_ID..."
    
    aws ssm send-command \
        --instance-ids "$INSTANCE_ID" \
        --document-name "AWS-RunShellScript" \
        --parameters commands="$(cat /tmp/deploy.sh | sed "s|\$ECR_URL|$ECR_URL|g; s|\$ENVIRONMENT|$ENVIRONMENT|g; s|\$DB_HOST|$RDS_ENDPOINT|g; s|\$LOG_GROUP|/aws/ec2/$PROJECT_NAME/$ENVIRONMENT/app|g")" \
        --region "$AWS_REGION" \
        --query "Command.CommandId" \
        --output text
    
    echo "   ✅ Comando enviado"
done

# 8. Resumen
echo ""
echo "╔════════════════════════════════════════╗"
echo "║  ✅ DEPLOYMENT COMPLETADO             ║"
echo "╚════════════════════════════════════════╝"
echo ""
echo "Resumen:"
echo "  ASG: $ASG_NAME"
echo "  Instancias: $(echo $INSTANCES | wc -w)"
echo "  Imagen: $ECR_URL:latest"
echo "  RDS: $RDS_ENDPOINT"
echo "  VPC: $VPC_ID"
echo ""
echo "Próximos pasos:"
echo "  1. Verificar logs en CloudWatch"
echo "  2. Hacer health check en puerto 8080"
echo "  3. Monitorear con CloudWatch Dashboards"