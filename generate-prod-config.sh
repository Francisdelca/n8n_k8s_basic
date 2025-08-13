#!/bin/bash

# ========================================
# GENERADOR DE CONFIGURACIÓN DE PRODUCCIÓN
# ========================================
# 
# Este script genera values-prod.yaml a partir de variables de entorno
# 
# USO:
# 1. Copia env.example a .env: cp env.example .env
# 2. Edita .env con tus valores reales
# 3. Ejecuta: ./generate-prod-config.sh
# 4. Instala: helm install n8n-prod . -f values-prod.yaml

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Generando configuración de producción para n8n...${NC}"

# Verificar que .env existe
if [ ! -f .env ]; then
    echo -e "${RED}❌ Error: Archivo .env no encontrado${NC}"
    echo -e "${YELLOW}💡 Solución: Copia env.example a .env y edítalo${NC}"
    echo -e "   cp env.example .env"
    echo -e "   # Edita .env con tus valores reales"
    exit 1
fi

# Cargar variables de entorno
echo -e "${BLUE}📖 Cargando variables de entorno...${NC}"
source .env

# Verificar variables críticas
echo -e "${BLUE}🔍 Verificando variables críticas...${NC}"

# Lista de variables obligatorias
REQUIRED_VARS=(
    "N8N_DOMAIN"
    "N8N_EMAIL"
    "DB_PASSWORD"
    "REDIS_PASSWORD"
    "N8N_ENCRYPTION_KEY"
    "N8N_ADMIN_PASSWORD"
    "STORAGE_CLASS"
)

# Verificar cada variable
for var in "${REQUIRED_VARS[@]}"; do
    if [ -z "${!var}" ] || [[ "${!var}" == *"tu-"* ]] || [[ "${!var}" == *"example"* ]]; then
        echo -e "${RED}❌ Error: Variable $var no está configurada correctamente${NC}"
        echo -e "   Valor actual: ${!var}"
        echo -e "   Edita .env y configura un valor real"
        exit 1
    fi
done

echo -e "${GREEN}✅ Todas las variables críticas están configuradas${NC}"

# Generar values-prod.yaml
echo -e "${BLUE}📝 Generando values-prod.yaml...${NC}"

cat > values-prod.yaml << EOF
# Configuración de n8n para PRODUCCIÓN
# Generado automáticamente desde variables de entorno
# Última generación: $(date)

image:
  repository: n8nio/n8n
  pullPolicy: IfNotPresent
  tag: "latest"

# Configuración del ingress para dominio y SSL
ingress:
  enabled: true
  annotations:
    kubernetes.io/ingress.class: "${INGRESS_CLASS}"
    cert-manager.io/cluster-issuer: "${CERT_MANAGER_ISSUER}"
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    nginx.ingress.kubernetes.io/force-ssl-redirect: "true"
  className: "${INGRESS_CLASS}"
  hosts:
    - host: "${N8N_DOMAIN}"
      paths:
        - path: /
          pathType: Prefix
  tls:
    - hosts:
        - "${N8N_DOMAIN}"
      secretName: "n8n-tls-cert"

# Configuración principal de n8n
main:
  config:
    DB_TYPE: "postgresdb"
    DB_POSTGRESDB_HOST: "${DB_HOST}"
    DB_POSTGRESDB_DATABASE: "${DB_NAME}"
    DB_POSTGRESDB_USER: "${DB_USER}"
    DB_POSTGRESDB_PORT: "${DB_PORT}"
    DB_POSTGRESDB_SCHEMA: "${DB_SCHEMA}"
    
    REDIS_HOST: "${REDIS_HOST}"
    REDIS_PORT: "${REDIS_PORT}"
    REDIS_DB: "${REDIS_DB}"
    
    GENERIC_HOST: "${N8N_DOMAIN}"
    N8N_HOST: "${N8N_DOMAIN}"
    N8N_PROTOCOL: "https"
    N8N_PORT: "443"
    N8N_WEBHOOK_URL: "https://${N8N_DOMAIN}/"
    
    N8N_ENCRYPTION_KEY: "${N8N_ENCRYPTION_KEY}"
    N8N_USER_MANAGEMENT_DISABLED: "false"
    N8N_BASIC_AUTH_ACTIVE: "true"
    N8N_BASIC_AUTH_USER: "${N8N_ADMIN_USER}"
    
    N8N_LOG_LEVEL: "${LOG_LEVEL}"
    N8N_LOG_OUTPUT: "${LOG_OUTPUT}"
    
    N8N_EXECUTIONS_MODE: "regular"
    N8N_EXECUTIONS_TIMEOUT: "${EXECUTION_TIMEOUT}"
    N8N_EXECUTIONS_TIMEOUT_MAX: "${EXECUTION_TIMEOUT_MAX}"

  secret:
    DB_POSTGRESDB_PASSWORD: "${DB_PASSWORD}"
    REDIS_PASSWORD: "${REDIS_PASSWORD}"
    N8N_BASIC_AUTH_PASSWORD: "${N8N_ADMIN_PASSWORD}"

  service:
    type: ClusterIP
    port: 5678

  persistence:
    enabled: true
    type: dynamic
    storageClass: "${STORAGE_CLASS}"
    accessModes:
      - ReadWriteOnce
    size: "${STORAGE_SIZE}"

  resources:
    requests:
      cpu: "${CPU_REQUEST}"
      memory: "${MEMORY_REQUEST}"
    limits:
      cpu: "${CPU_LIMIT}"
      memory: "${MEMORY_LIMIT}"

  podSecurityContext:
    runAsNonRoot: true
    runAsUser: 1000
    runAsGroup: 1000
    fsGroup: 1000

  securityContext:
    capabilities:
      drop:
        - ALL
    readOnlyRootFilesystem: false
    runAsNonRoot: true
    runAsUser: 1000

  livenessProbe:
    httpGet:
      path: /healthz
      port: http
    initialDelaySeconds: 60
    periodSeconds: 30
    timeoutSeconds: 10
    failureThreshold: 3
    successThreshold: 1

  readinessProbe:
    httpGet:
      path: /healthz
      port: http
    initialDelaySeconds: 30
    periodSeconds: 10
    timeoutSeconds: 5
    failureThreshold: 3
    successThreshold: 1

  deploymentStrategy:
    type: "RollingUpdate"
    maxSurge: "25%"
    maxUnavailable: "25%"

  replicaCount: ${MIN_REPLICAS}

  autoscaling:
    enabled: true
    minReplicas: ${MIN_REPLICAS}
    maxReplicas: ${MAX_REPLICAS}
    targetCPUUtilizationPercentage: ${TARGET_CPU}
    targetMemoryUtilizationPercentage: ${TARGET_MEMORY}

# Configuración de Redis (Valkey)
valkey:
  enabled: true
  architecture: standalone
  
  primary:
    persistence:
      enabled: true
      storageClass: "${STORAGE_CLASS}"
      size: "${REDIS_STORAGE_SIZE}"
      accessModes:
        - ReadWriteOnce
    
    resources:
      requests:
        cpu: "250m"
        memory: "512Mi"
      limits:
        cpu: "500m"
        memory: "1Gi"

# Configuración generada automáticamente
# Archivo: values-prod.yaml
# Generado: $(date)
# Variables usadas: ${#REQUIRED_VARS[@]} variables críticas
EOF

echo -e "${GREEN}✅ Archivo values-prod.yaml generado exitosamente${NC}"
echo -e "${BLUE}📋 Resumen de configuración:${NC}"
echo -e "   🌐 Dominio: ${N8N_DOMAIN}"
echo -e "   📧 Email: ${N8N_EMAIL}"
echo -e "   💾 Storage: ${STORAGE_CLASS}"
echo -e "   🔒 Réplicas: ${MIN_REPLICAS}-${MAX_REPLICAS}"
echo -e "   ⚡ CPU: ${CPU_REQUEST} - ${CPU_LIMIT}"
echo -e "   🧠 Memoria: ${MEMORY_REQUEST} - ${MEMORY_LIMIT}"

echo -e "${GREEN}🚀 Ahora puedes instalar n8n con:${NC}"
echo -e "   helm install n8n-prod . -f values-prod.yaml"

echo -e "${YELLOW}⚠️  Recuerda:${NC}"
echo -e "   - Tener cert-manager instalado"
echo -e "   - Tener nginx-ingress funcionando"
echo -e "   - Configurar DNS para ${N8N_DOMAIN}"
echo -e "   - Aplicar letsencrypt-issuer.yaml antes"
