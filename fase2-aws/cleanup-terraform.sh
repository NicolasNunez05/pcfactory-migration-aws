# Archivo: fase2-aws/cleanup-terraform.sh

set -e

echo "🧹 Limpiando recursos antes de terraform apply..."

cd "$(dirname "$0")/environments/dev"

# 1. Limpiar backend
echo "🗑️  Eliminando .terraform y .terraform.lock.hcl..."
rm -rf .terraform
rm -f .terraform.lock.hcl

# 2. Eliminar secretos en "scheduled for deletion"
echo "🗑️  Eliminando secretos programados para eliminar..."
aws secretsmanager delete-secret \
  --secret-id pcfactory-migration/dev/rds/master \
  --force-delete-without-recovery \
  --region us-east-1 2>/dev/null || echo "   (Secret RDS no encontrado, OK)"

aws secretsmanager delete-secret \
  --secret-id pcfactory-migration/dev/redis/auth \
  --force-delete-without-recovery \
  --region us-east-1 2>/dev/null || echo "   (Secret Redis no encontrado, OK)"

# 3. Limpiar buckets S3
echo "🗑️  Limpiando buckets S3..."
for bucket in pcfactory-migration-backups-dev pcfactory-migration-logs-dev pcfactory-migration-artifacts-dev; do
  if aws s3api head-bucket --bucket "$bucket" --region us-east-1 2>/dev/null; then
    echo "   Vaciando $bucket..."
    aws s3 rm s3://$bucket --recursive --region us-east-1 2>/dev/null || true
    echo "   Eliminando $bucket..."
    aws s3api delete-bucket --bucket $bucket --region us-east-1 2>/dev/null || true
  fi
done

echo ""
echo "✅ Limpieza completada"
echo "🔄 Ejecutando: terraform init -reconfigure"
terraform init -reconfigure

echo "✅ ¡Listo para terraform apply!"