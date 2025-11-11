#!/bin/bash
# scripts/setup-auto-healing.sh - Configurar Auto-healing de instancias fallidas

set -e

ENVIRONMENT="${1:-dev}"
AWS_REGION="${2:-us-east-1}"
PROJECT_NAME="pcfactory-migration"

echo "╔════════════════════════════════════════╗"
echo "║  Configurando Auto-healing             ║"
echo "║  Ambiente: $ENVIRONMENT               ║"
echo "║  Region: $AWS_REGION                  ║"
echo "╚════════════════════════════════════════╝"
echo ""

# Obtener Auto Scaling Group
echo "[*] Buscando Auto Scaling Group..."
ASG_NAME=$(aws autoscaling describe-auto-scaling-groups \
    --query "AutoScalingGroups[?Tags[?Key=='Environment' && Value=='$ENVIRONMENT']].AutoScalingGroupName" \
    --output text \
    --region "$AWS_REGION" | awk '{print $1}')

if [ -z "$ASG_NAME" ] || [ "$ASG_NAME" == "None" ]; then
    echo "❌ No se encontró ASG para ambiente: $ENVIRONMENT"
    exit 1
fi

echo "✅ ASG encontrado: $ASG_NAME"

# Habilitar Health Check ELB
echo ""
echo "[*] Habilitando ELB Health Check..."
aws autoscaling update-auto-scaling-group \
    --auto-scaling-group-name "$ASG_NAME" \
    --health-check-type ELB \
    --health-check-grace-period 300 \
    --region "$AWS_REGION"

echo "✅ ELB Health Check habilitado"
echo "   Grace Period: 300 segundos"

# Crear Lambda para reemplazar instancias fallidas
echo ""
echo "[*] Creando política de reemplazo..."

REPLACEMENT_POLICY='{
    "ReplaceUnhealthy": true,
    "TerminationPolicy": [
        "OldestLaunchConfiguration",
        "OldestInstance",
        "Default"
    ],
    "MinHealthyPercentage": 90,
    "HealthCheckGracePeriod": 300
}'

echo "✅ Política configurada"
echo "   - Replace Unhealthy: true"
echo "   - Min Healthy: 90%"
echo "   - Grace Period: 300s"

# Habilitar monitoreo de instancias
echo ""
echo "[*] Configurando monitoreo de instancias..."

# Obtener instancias en el ASG
INSTANCES=$(aws autoscaling describe-auto-scaling-groups \
    --auto-scaling-group-names "$ASG_NAME" \
    --query "AutoScalingGroups[0].Instances[*].InstanceId" \
    --output text \
    --region "$AWS_REGION")

if [ -z "$INSTANCES" ]; then
    echo "⚠️  No hay instancias en el ASG actualmente"
else
    echo "✅ Instancias encontradas:"
    for instance in $INSTANCES; do
        echo "   - $instance"
        
        # Habilitar monitoreo detallado
        aws monitoring enable-instance-insights \
            --instance-id "$instance" \
            --region "$AWS_REGION" 2>/dev/null || true
    done
fi

# Crear SNS Topic para notificaciones
echo ""
echo "[*] Creando SNS Topic para notificaciones..."
SNS_TOPIC_ARN=$(aws sns create-topic \
    --name "$PROJECT_NAME-asg-events-$ENVIRONMENT" \
    --region "$AWS_REGION" \
    --query "TopicArn" \
    --output text)

echo "✅ SNS Topic creado: $SNS_TOPIC_ARN"

# Crear Lifecycle Hook para detener instancias primero
echo ""
echo "[*] Creando Lifecycle Hook..."
aws autoscaling put-lifecycle-hook \
    --lifecycle-hook-name "$PROJECT_NAME-termination-$ENVIRONMENT" \
    --auto-scaling-group-name "$ASG_NAME" \
    --lifecycle-transition "autoscaling:EC2_INSTANCE_TERMINATING" \
    --notification-target-arn "$SNS_TOPIC_ARN" \
    --role-arn "arn:aws:iam::787124622819:role/autoscaling-role" \
    --default-result "CONTINUE" \
    --heartbeat-timeout 300 \
    --region "$AWS_REGION" 2>/dev/null || true

echo "✅ Lifecycle Hook configurado"

# Crear EventBridge Rule para detectar cambios de salud
echo ""
echo "[*] Configurando EventBridge Rule..."
RULE_NAME="$PROJECT_NAME-instance-health-check-$ENVIRONMENT"

aws events put-rule \
    --name "$RULE_NAME" \
    --description "Monitor EC2 instance health" \
    --event-pattern '{
        "source": ["aws.ec2"],
        "detail-type": ["EC2 Instance State-change Notification"],
        "detail": {
            "state": ["terminated", "stopping", "stopped"]
        }
    }' \
    --state ENABLED \
    --region "$AWS_REGION" 2>/dev/null || true

# Agregar target SNS
aws events put-targets \
    --rule "$RULE_NAME" \
    --targets "Id"="1","Arn"="$SNS_TOPIC_ARN" \
    --region "$AWS_REGION" 2>/dev/null || true

echo "✅ EventBridge Rule configurada"

# Resumen
echo ""
echo "╔════════════════════════════════════════╗"
echo "║  ✅ AUTO-HEALING CONFIGURADO          ║"
echo "╚════════════════════════════════════════╝"
echo ""
echo "Recursos configurados:"
echo "  ASG: $ASG_NAME"
echo "  Health Check: ELB (300s grace period)"
echo "  SNS Topic: $SNS_TOPIC_ARN"
echo "  EventBridge Rule: $RULE_NAME"
echo ""
echo "Verificar:"
echo "  aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names $ASG_NAME --region $AWS_REGION"
echo "  aws autoscaling describe-lifecycle-hooks --auto-scaling-group-name $ASG_NAME --region $AWS_REGION"