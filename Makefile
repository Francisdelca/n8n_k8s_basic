# ========================================
# MAKEFILE PARA n8n EN KUBERNETES
# ========================================

.PHONY: help install-local install-prod generate-prod clean uninstall-local uninstall-prod status logs

# Variables por defecto
RELEASE_NAME ?= n8n-local
NAMESPACE ?= default

# Colores para output
GREEN := \033[0;32m
YELLOW := \033[1;33m
BLUE := \033[0;34m
NC := \033[0m # No Color

help: ## Mostrar esta ayuda
	@echo "$(BLUE)🚀 Comandos disponibles para n8n en Kubernetes:$(NC)"
	@echo ""
	@echo "$(GREEN)Instalación:$(NC)"
	@echo "  make install-local     - Instalar n8n para desarrollo local"
	@echo "  make install-prod      - Instalar n8n para producción"
	@echo "  make generate-prod     - Generar configuración de producción desde .env"
	@echo ""
	@echo "$(GREEN)Gestión:$(NC)"
	@echo "  make status            - Ver estado del deployment"
	@echo "  make logs              - Ver logs del pod"
	@echo "  make uninstall-local   - Desinstalar n8n local"
	@echo "  make uninstall-prod    - Desinstalar n8n de producción"
	@echo "  make clean             - Limpiar archivos generados"
	@echo ""
	@echo "$(GREEN)Configuración:$(NC)"
	@echo "  make setup-env         - Configurar archivo .env desde ejemplo"
	@echo "  make validate-env      - Validar variables de entorno"
	@echo ""
	@echo "$(YELLOW)Ejemplos:$(NC)"
	@echo "  RELEASE_NAME=mi-n8n make install-local"
	@echo "  NAMESPACE=n8n make install-prod"

setup-env: ## Configurar archivo .env desde ejemplo
	@if [ ! -f .env ]; then \
		cp env.example .env; \
		echo "$(GREEN)✅ Archivo .env creado desde env.example$(NC)"; \
		echo "$(YELLOW)⚠️  Edita .env con tus valores reales antes de continuar$(NC)"; \
	else \
		echo "$(YELLOW)⚠️  El archivo .env ya existe$(NC)"; \
	fi

validate-env: ## Validar variables de entorno
	@if [ -f .env ]; then \
		echo "$(BLUE)🔍 Validando variables de entorno...$(NC)"; \
		source .env; \
		required_vars="N8N_DOMAIN N8N_EMAIL DB_PASSWORD REDIS_PASSWORD N8N_ENCRYPTION_KEY N8N_ADMIN_PASSWORD STORAGE_CLASS"; \
		for var in $$required_vars; do \
			if [ -z "$${!var}" ] || [[ "$${!var}" == *"tu-"* ]] || [[ "$${!var}" == *"example"* ]]; then \
				echo "$(YELLOW)⚠️  Variable $$var no configurada correctamente$(NC)"; \
			else \
				echo "$(GREEN)✅ $$var: $${!var}$(NC)"; \
			fi; \
		done; \
	else \
		echo "$(YELLOW)⚠️  Archivo .env no encontrado. Ejecuta: make setup-env$(NC)"; \
	fi

generate-prod: ## Generar configuración de producción desde .env
	@echo "$(BLUE)🚀 Generando configuración de producción...$(NC)"
	@./generate-prod-config.sh

install-local: ## Instalar n8n para desarrollo local
	@echo "$(BLUE)🚀 Instalando n8n para desarrollo local...$(NC)"
	helm install $(RELEASE_NAME) . -f values.yaml --namespace $(NAMESPACE) --create-namespace
	@echo "$(GREEN)✅ n8n instalado localmente$(NC)"
	@echo "$(YELLOW)🌐 Accede en: http://localhost:5678 (port-forward) o puerto NodePort$(NC)"

install-prod: generate-prod ## Instalar n8n para producción
	@echo "$(BLUE)🚀 Instalando n8n para producción...$(NC)"
	helm install $(RELEASE_NAME) . -f values-prod.yaml --namespace $(NAMESPACE) --create-namespace
	@echo "$(GREEN)✅ n8n instalado en producción$(NC)"
	@echo "$(YELLOW)🌐 Accede en: https://$(shell grep N8N_DOMAIN .env | cut -d'=' -f2)$(NC)"

status: ## Ver estado del deployment
	@echo "$(BLUE)📊 Estado del deployment $(RELEASE_NAME)...$(NC)"
	kubectl get deployment -l app.kubernetes.io/instance=$(RELEASE_NAME) -n $(NAMESPACE)
	@echo ""
	@echo "$(BLUE)📊 Estado de los pods...$(NC)"
	kubectl get pods -l app.kubernetes.io/instance=$(RELEASE_NAME) -n $(NAMESPACE)
	@echo ""
	@echo "$(BLUE)📊 Estado de los servicios...$(NC)"
	kubectl get svc -l app.kubernetes.io/instance=$(RELEASE_NAME) -n $(NAMESPACE)

logs: ## Ver logs del pod
	@echo "$(BLUE)📝 Mostrando logs del pod $(RELEASE_NAME)...$(NC)"
	kubectl logs -f deployment/$(RELEASE_NAME)-n8n -n $(NAMESPACE)

uninstall-local: ## Desinstalar n8n local
	@echo "$(BLUE)🗑️  Desinstalando n8n local...$(NC)"
	helm uninstall $(RELEASE_NAME) -n $(NAMESPACE)
	@echo "$(GREEN)✅ n8n local desinstalado$(NC)"

uninstall-prod: ## Desinstalar n8n de producción
	@echo "$(BLUE)🗑️  Desinstalando n8n de producción...$(NC)"
	helm uninstall $(RELEASE_NAME) -n $(NAMESPACE)
	@echo "$(GREEN)✅ n8n de producción desinstalado$(NC)"

clean: ## Limpiar archivos generados
	@echo "$(BLUE)🧹 Limpiando archivos generados...$(NC)"
	@if [ -f values-prod.yaml ]; then \
		rm values-prod.yaml; \
		echo "$(GREEN)✅ values-prod.yaml eliminado$(NC)"; \
	else \
		echo "$(YELLOW)⚠️  values-prod.yaml no encontrado$(NC)"; \
	fi

port-forward: ## Hacer port-forward para acceso local
	@echo "$(BLUE)🔗 Iniciando port-forward...$(NC)"
	@echo "$(YELLOW)🌐 Accede en: http://localhost:5678$(NC)"
	@echo "$(YELLOW)⏹️  Presiona Ctrl+C para detener$(NC)"
	kubectl port-forward svc/$(RELEASE_NAME)-n8n 5678:5678 -n $(NAMESPACE)

# Comandos de desarrollo adicionales
dev-setup: ## Configurar entorno de desarrollo completo
	@echo "$(BLUE)🔧 Configurando entorno de desarrollo...$(NC)"
	@make setup-env
	@echo "$(GREEN)✅ Entorno de desarrollo configurado$(NC)"
	@echo "$(YELLOW)📝 Edita .env con tus valores y ejecuta: make install-local$(NC)"

prod-setup: ## Configurar entorno de producción completo
	@echo "$(BLUE)🔧 Configurando entorno de producción...$(NC)"
	@make setup-env
	@echo "$(GREEN)✅ Entorno de producción configurado$(NC)"
	@echo "$(YELLOW)📝 Edita .env con tus valores y ejecuta: make install-prod$(NC)"
