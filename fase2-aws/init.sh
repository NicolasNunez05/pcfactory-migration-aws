set -e  # Salir si hay error

echo "🔧 Inicializando Terraform..."

cd "$(dirname "$0")/environments/dev"

echo "🧹 Limpiando archivos de Terraform anteriores..."
rm -rf .terraform
rm -f .terraform.lock.hcl

echo "🔄 Inicializando backend S3..."
terraform init -reconfigure

echo "✅ Validando configuración de Terraform..."
terraform validate

echo "✅ ¡Inicialización completada!"
echo ""
echo "Próximos pasos:"
echo "  terraform plan"
echo "  terraform apply"