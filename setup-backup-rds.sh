#!/bin/bash
# scripts/setup-backup-rds.sh - Configurar backup automático RDS a S3

set -e

ENVIRONMENT="${1:-dev}"
AWS_REGION="${2:-us-east-1}"
PROJECT_NAME="pcfactory-migration"
S3_BACKUP_BUCKET="$PROJECT_NAME-backups-$ENVIRONMENT"

echo "╔════════════════════════════════════════╗"
echo "║  Configurando Backup RDS → S3          ║"
echo "║  Ambiente: $ENVIRONMENT               ║"
echo "║  Region: $AWS_REGION                  ║"
echo "╚════════════════════════════════════════╝"
echo ""

# Crear bucket S3 si no existe
echo "[*] Verificando/Creando bucket S3..."
if aws s3 ls "s3://$S3_BACKUP_BUCKET" --region "$AWS_REGION" 2>/dev/null; then
    echo "✅ Bucket ya existe: $S3_BACKUP_BUCKET"
else
    echo "   Creando bucket: $S3_BACKUP_BUCKET"
    aws s3 mb "s3://$S3_BACKUP_BUCKET" \
        --region "$AWS_REGION" \
        --create-bucket-configuration LocationConstraint="$AWS_REGION" 2>/dev/null || true
    
    # Habilitar versionado
    aws s3api put-bucket-versioning \
        --bucket "$S3_BACKUP_BUCKET" \
        --versioning-configuration Status=Enabled \
        --region "$AWS_REGION"
    
    # Habilitar cifrado
    aws s3api put-bucket-encryption \
        --bucket "$S3_BACKUP_BUCKET" \
        --server-side-encryption-configuration '{
            "Rules": [
                {
                    "ApplyServerSideEncryptionByDefault": {
                        "SSEAlgorithm": "AES256"
                    }
                }
            ]
        }' \
        --region "$AWS_REGION"
    
    echo "✅ Bucket creado: $S3_BACKUP_BUCKET"
fi

# Configurar lifecycle policy
echo ""
echo "[*] Configurando Lifecycle Policy..."
LIFECYCLE_POLICY='{
    "Rules": [
        {
            "Id": "Archive old backups",
            "Status": "Enabled",
            "Transitions": [
                {
                    "Days": 30,
                    "StorageClass": "STANDARD_IA"
                },
                {
                    "Days": 90,
                    "StorageClass": "GLACIER"
                }
            ],
            "Expiration": {
                "Days": 365
            }
        }
    ]
}'

aws s3api put-bucket-lifecycle-configuration \
    --bucket "$S3_BACKUP_BUCKET" \
    --lifecycle-configuration "$LIFECYCLE_POLICY" \
    --region "$AWS_REGION"

echo "✅ Lifecycle Policy configurada"

# Obtener instancia RDS
echo ""
echo "[*] Buscando instancia RDS..."
RDS_INSTANCE=$(aws rds describe-db-instances \
    --filters "Name=db-instance-id,Values=pcfactory*" \
    --region "$AWS_REGION" \
    --query "DBInstances[0].DBInstanceIdentifier" \
    --output text 2>/dev/null || echo "")

if [ "$RDS_INSTANCE" == "None" ] || [ -z "$RDS_INSTANCE" ]; then
    echo "⚠️  No se encontró instancia RDS"
    echo "    Cuando tengas RDS, ejecuta:"
    echo "    aws rds create-db-snapshot --db-instance-identifier <instance> --db-snapshot-identifier pcfactory-manual-backup-$(date +%s)"
else
    echo "✅ Instancia RDS encontrada: $RDS_INSTANCE"
    
    # Habilitar backup automático
    echo ""
    echo "[*] Habilitando backup automático..."
    aws rds modify-db-instance \
        --db-instance-identifier "$RDS_INSTANCE" \
        --backup-retention-period 30 \
        --preferred-backup-window "03:00-04:00" \
        --preferred-maintenance-window "sun:04:00-sun:05:00" \
        --apply-immediately \
        --region "$AWS_REGION"
    
    echo "✅ Backup automático habilitado"
    echo "   Retención: 30 días"
    echo "   Ventana de backup: 03:00-04:00 UTC"
fi

# Crear Lambda para exportar backups a S3 (opcional)
echo ""
echo "[*] Información sobre exportación de backups..."
echo "    Para exportar snapshots RDS a S3, usa:"
echo "    aws rds start-export-task --export-task-identifier pcfactory-export-\$(date +%s) --source-arn arn:aws:rds:$AWS_REGION:787124622819:snapshot:pcfactory-snapshot --s3-bucket-name $S3_BACKUP_BUCKET --s3-prefix rds-exports/"

# Resumen
echo ""
echo "╔════════════════════════════════════════╗"
echo "║  ✅ BACKUP CONFIGURADO                ║"
echo "╚════════════════════════════════════════╝"
echo ""
echo "Recursos creados:"
echo "  S3 Bucket: s3://$S3_BACKUP_BUCKET"
echo "  Lifecycle: 30d STANDARD_IA → 90d GLACIER → 365d DELETE"
echo "  RDS Backup: $RDS_INSTANCE (si existe)"
echo ""
echo "Verificar:"
echo "  aws s3 ls s3://$S3_BACKUP_BUCKET/"
echo "  aws rds describe-db-instances --region $AWS_REGION"