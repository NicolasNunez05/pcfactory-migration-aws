#!/bin/bash
# scripts/setup-cloudwatch.sh - Configurar CloudWatch dashboards y alarmas

set -e

ENVIRONMENT="${1:-dev}"
AWS_REGION="${2:-us-east-1}"
PROJECT_NAME="pcfactory-migration"

echo "╔════════════════════════════════════════╗"
echo "║  Configurando CloudWatch               ║"
echo "║  Ambiente: $ENVIRONMENT               ║"
echo "║  Region: $AWS_REGION                  ║"
echo "╚════════════════════════════════════════╝"
echo ""

# Crear SNS Topic para alarmas
echo "[*] Creando SNS Topic para alarmas..."
SNS_TOPIC_ARN=$(aws sns create-topic \
    --name "$PROJECT_NAME-alerts-$ENVIRONMENT" \
    --region "$AWS_REGION" \
    --query "TopicArn" \
    --output text)

echo "✅ SNS Topic creado: $SNS_TOPIC_ARN"

# Suscribir email a SNS
echo ""
echo "[*] Suscribiendo email a SNS..."
aws sns subscribe \
    --topic-arn "$SNS_TOPIC_ARN" \
    --protocol email \
    --notification-endpoint "nicolasnunezalvarezaws@gmail.com" \
    --region "$AWS_REGION"

echo "✅ Verifica tu email para confirmar la suscripción"

# Crear Log Group para aplicación
echo ""
echo "[*] Creando Log Group para aplicación..."
LOG_GROUP_NAME="/aws/ec2/$PROJECT_NAME/$ENVIRONMENT/app"
aws logs create-log-group \
    --log-group-name "$LOG_GROUP_NAME" \
    --region "$AWS_REGION" 2>/dev/null || echo "   (Log group ya existe)"

aws logs put-retention-policy \
    --log-group-name "$LOG_GROUP_NAME" \
    --retention-in-days 30 \
    --region "$AWS_REGION"

echo "✅ Log Group: $LOG_GROUP_NAME"

# Crear Log Group para sistema
echo ""
echo "[*] Creando Log Group para sistema..."
SYS_LOG_GROUP_NAME="/aws/ec2/$PROJECT_NAME/$ENVIRONMENT/system"
aws logs create-log-group \
    --log-group-name "$SYS_LOG_GROUP_NAME" \
    --region "$AWS_REGION" 2>/dev/null || echo "   (Log group ya existe)"

aws logs put-retention-policy \
    --log-group-name "$SYS_LOG_GROUP_NAME" \
    --retention-in-days 7 \
    --region "$AWS_REGION"

echo "✅ Log Group: $SYS_LOG_GROUP_NAME"

# Crear Metric Filter para errores
echo ""
echo "[*] Creando Metric Filter para errores..."
aws logs put-metric-filter \
    --log-group-name "$LOG_GROUP_NAME" \
    --filter-name "ErrorMetric" \
    --filter-pattern "[ERROR]" \
    --metric-transformations metricName="ApplicationErrors",metricNamespace="$PROJECT_NAME",metricValue="1" \
    --region "$AWS_REGION"

echo "✅ Metric Filter creado"

# Crear Alarma para errores
echo ""
echo "[*] Creando Alarma para errores..."
aws cloudwatch put-metric-alarm \
    --alarm-name "$PROJECT_NAME-app-errors-$ENVIRONMENT" \
    --alarm-description "Alerta cuando hay errores en la aplicación" \
    --metric-name "ApplicationErrors" \
    --namespace "$PROJECT_NAME" \
    --statistic "Sum" \
    --period 300 \
    --threshold 5 \
    --comparison-operator "GreaterThanOrEqualToThreshold" \
    --evaluation-periods 1 \
    --alarm-actions "$SNS_TOPIC_ARN" \
    --region "$AWS_REGION"

echo "✅ Alarma creada: ApplicationErrors"

# Crear Dashboard
echo ""
echo "[*] Creando CloudWatch Dashboard..."

DASHBOARD_BODY='{
  "widgets": [
    {
      "type": "metric",
      "properties": {
        "metrics": [
          [ "AWS/EC2", "CPUUtilization", { "stat": "Average" } ],
          [ ".", "NetworkIn" ],
          [ ".", "NetworkOut" ]
        ],
        "period": 300,
        "stat": "Average",
        "region": "'$AWS_REGION'",
        "title": "EC2 Metrics"
      }
    },
    {
      "type": "log",
      "properties": {
        "query": "fields @timestamp, @message | filter @message like /ERROR/ | stats count() by bin(5m)",
        "region": "'$AWS_REGION'",
        "title": "Application Errors (5min bins)"
      }
    },
    {
      "type": "metric",
      "properties": {
        "metrics": [
          [ "'$PROJECT_NAME'", "ApplicationErrors", { "stat": "Sum" } ]
        ],
        "period": 300,
        "stat": "Sum",
        "region": "'$AWS_REGION'",
        "title": "Custom Application Errors"
      }
    }
  ]
}'

aws cloudwatch put-dashboard \
    --dashboard-name "$PROJECT_NAME-$ENVIRONMENT" \
    --dashboard-body "$DASHBOARD_BODY" \
    --region "$AWS_REGION"

echo "✅ Dashboard creado: $PROJECT_NAME-$ENVIRONMENT"

# Resumen
echo ""
echo "╔════════════════════════════════════════╗"
echo "║  ✅ CLOUDWATCH CONFIGURADO            ║"
echo "╚════════════════════════════════════════╝"
echo ""
echo "Recursos creados:"
echo "  SNS Topic: $SNS_TOPIC_ARN"
echo "  Log Group (App): $LOG_GROUP_NAME"
echo "  Log Group (System): $SYS_LOG_GROUP_NAME"
echo "  Dashboard: https://console.aws.amazon.com/cloudwatch/home?region=$AWS_REGION#dashboards:name=$PROJECT_NAME-$ENVIRONMENT"