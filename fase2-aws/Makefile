.PHONY: apply destroy plan init validate help

ENVIRONMENT ?= dev

help:
	@echo "Comandos disponibles:"
	@echo "  make init ENV=dev       - Inicializar Terraform"
	@echo "  make plan ENV=dev       - Ver cambios"
	@echo "  make apply ENV=dev      - Aplicar cambios"
	@echo "  make destroy ENV=dev    - Destruir infraestructura"
	@echo "  make validate ENV=dev   - Validar configuración"
	@echo ""
	@echo "Variables: ENV=[dev|staging|prod] (default: dev)"

init:
	@cd environments/$(ENVIRONMENT) && terraform init -upgrade && echo "✅ Terraform inicializado"

validate:
	@cd environments/$(ENVIRONMENT) && terraform validate && echo "✅ Validación exitosa"

plan:
	@cd environments/$(ENVIRONMENT) && terraform plan

apply:
	@./scripts/tf-apply-destroy.sh $(ENVIRONMENT) apply

destroy:
	@./scripts/tf-apply-destroy.sh $(ENVIRONMENT) destroy

refresh:
	@cd environments/$(ENVIRONMENT) && terraform refresh && echo "✅ Estado refrescado"

output:
	@cd environments/$(ENVIRONMENT) && terraform output

clean:
	@rm -f environments/$(ENVIRONMENT)/*.tfplan
	@rm -f environments/*/outputs*.json
	@echo "✅ Archivos temporales limpiados"

state-list:
	@cd environments/$(ENVIRONMENT) && terraform state list

state-show:
	@cd environments/$(ENVIRONMENT) && terraform state show
