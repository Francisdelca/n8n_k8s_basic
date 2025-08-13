# n8n en Kubernetes - Guía de Despliegue en Producción

Este repositorio contiene la configuración para desplegar [n8n](https://n8n.io/) en Kubernetes usando el chart de Helm oficial de [open-8gears](https://artifacthub.io/packages/helm/open-8gears/n8n).

## 📋 Prerrequisitos

- Kubernetes cluster 1.19+
- Helm 3.0+
- kubectl configurado
- cert-manager instalado (para certificados SSL)
- StorageClass configurado en el cluster

## 🚀 Flujo de Despliegue Estándar

### 1. Configuración del values.yaml

Antes de instalar, debes configurar las variables críticas en `values.yaml`:

#### Variables Obligatorias

**Base de Datos PostgreSQL:**
```yaml
main:
  config:
    n8n:
      db:
        type: postgresdb
        postgresdb:
          host: TU_HOST_POSTGRES
          port: 5432
          database: n8n
          user: n8n
  secret:
    n8n:
      db:
        postgresdb:
          password: "TU_PASSWORD_POSTGRES"
```

**Redis:**
```yaml
main:
  config:
    n8n:
      redis:
        host: TU_HOST_REDIS
        port: 6379
  secret:
    n8n:
      redis:
        password: "TU_PASSWORD_REDIS"
```

**Clave de Encriptación:**
```yaml
main:
  secret:
    n8n:
      encryption_key: "GENERA_UNA_CLAVE_DE_32_CARACTERES_ALEATORIA"
```

**Host y Protocolo:**
```yaml
main:
  config:
    n8n:
      host: "tu-dominio.com"
      protocol: https
```

#### Configuración de Ingress (Opcional)

Para acceso externo con SSL:
```yaml
ingress:
  enabled: true
  className: "nginx"  # o tu clase de ingress
  hosts:
    - host: tu-dominio.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - hosts:
        - tu-dominio.com
      secretName: n8n-tls
  annotations:
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
```

#### Autoscaling (Opcional)

```yaml
main:
  autoscaling:
    enabled: true
    minReplicas: 1
    maxReplicas: 3
    targetCPUUtilizationPercentage: 20
```

**Nota**: El autoscaling se puede configurar aquí o gestionar manualmente después del despliegue.

### 2. Instalación del Servicio

```bash
helm install n8n oci://8gears.container-registry.com/library/n8n --version 1.0.0 -f values.yaml
```

Este comando instala directamente desde el registro OCI de 8gears e inicia el servicio.

### 3. Diagnóstico del Despliegue

#### Verificar Estado de los Pods
```bash
kubectl get pods -l app.kubernetes.io/name=n8n
kubectl describe pod -l app.kubernetes.io/name=n8n
```

#### Verificar Servicios
```bash
kubectl get svc -l app.kubernetes.io/name=n8n
kubectl get endpoints -l app.kubernetes.io/name=n8n
```

#### Verificar HPA (si está habilitado)
```bash
kubectl get hpa
kubectl describe hpa n8n
```

#### Logs de la Aplicación
```bash
kubectl logs -l app.kubernetes.io/name=n8n -f
```

### 4. Verificación del Dominio y SSL

#### Verificar Ingress
```bash
kubectl get ingress
kubectl describe ingress n8n
```

#### Configurar Certificado SSL (si usas cert-manager)

Aplica el ClusterIssuer de Let's Encrypt:
```bash
kubectl apply -f letsencrypt-example.yaml
```

Verifica el estado del certificado:
```bash
kubectl get certificaterequests
kubectl get certificates
```

### 5. Pruebas de Carga

El directorio `locust_test/` contiene scripts para probar la carga de tu instancia de n8n:

```bash
cd locust_test
pip install -r requirements.txt
locust -f locustfile.py --host=https://tu-dominio.com
```

Consulta el README de `locust_test/` para más detalles sobre las pruebas de carga.

## ⚙️ Configuraciones Adicionales del values.yaml

### Configuración de Base

El archivo `values.yaml` está configurado para un entorno de producción con:

- **Base de datos**: PostgreSQL externa
- **Cache**: Redis externo
- **Persistencia**: StorageClass dinámico (5Gi)
- **Recursos**: 500m CPU / 1Gi RAM (requests), 1500m CPU / 2Gi RAM (limits)
- **Health checks**: Configurados para `/healthz`

## 🔐 Configuración de SSL con Let's Encrypt

### 1. Instalar cert-manager

```bash
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml
```

### 2. Configurar ClusterIssuer

Modifica `letsencrypt-example.yaml` con tu email:

```yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    email: tu-email@dominio.com
    server: https://acme-v02.api.letsencrypt.org/directory
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
      - http01:
          ingress:
            class: nginx
```

### 3. Aplicar la configuración

```bash
kubectl apply -f letsencrypt-example.yaml
```

## 📊 Monitoreo y Escalado

### Verificar el estado del despliegue

```bash
kubectl get pods -l app.kubernetes.io/name=n8n
kubectl get svc -l app.kubernetes.io/name=n8n
kubectl get ingress -l app.kubernetes.io/name=n8n
```

### Logs de la aplicación

```bash
kubectl logs -l app.kubernetes.io/name=n8n -f
```

### Escalado manual

```bash
kubectl scale deployment n8n --replicas=3
```

## 🔧 Configuraciones Avanzadas

### Workers (Procesamiento en Background)

Para habilitar workers para procesamiento asíncrono:

```yaml
worker:
  enabled: true
  replicaCount: 2
  concurrency: 10
  resources:
    requests:
      cpu: "250m"
      memory: "512Mi"
    limits:
      cpu: "500m"
      memory: "1Gi"
```

### Webhooks

Para habilitar webhooks:

```yaml
webhook:
  enabled: true
  replicaCount: 2
  resources:
    requests:
      cpu: "100m"
      memory: "256Mi"
```

### Persistencia Personalizada

```yaml
main:
  persistence:
    storageClass: "tu-storage-class"
    size: "10Gi"
    accessModes:
      - ReadWriteMany  # Para múltiples nodos
```

## 🧪 Pruebas de Carga

El directorio `locust_test/` contiene scripts para probar la carga de tu instancia de n8n:

```bash
cd locust_test
pip install -r requirements.txt
locust -f locustfile.py --host=http://tu-dominio.com
```

## 🚨 Troubleshooting

### Problemas Comunes

1. **Pods no inician**: Verificar recursos del cluster y StorageClass
2. **Error de conexión a BD**: Verificar credenciales y conectividad de red
3. **SSL no funciona**: Verificar cert-manager y ClusterIssuer
4. **Persistencia falla**: Verificar StorageClass y permisos

### Comandos de Diagnóstico

```bash
# Verificar eventos
kubectl get events --sort-by='.lastTimestamp'

# Verificar configuración del pod
kubectl describe pod -l app.kubernetes.io/name=n8n

# Verificar logs de cert-manager
kubectl logs -n cert-manager -l app=cert-manager
```

## 📚 Recursos Adicionales

- [Documentación oficial de n8n](https://docs.n8n.io/)
- [Chart de Helm en ArtifactHub](https://artifacthub.io/packages/helm/open-8gears/n8n)
- [Documentación de cert-manager](https://cert-manager.io/docs/)
- [Guía de Kubernetes Ingress](https://kubernetes.io/docs/concepts/services-networking/ingress/)

## 🤝 Contribuciones

Las contribuciones son bienvenidas. Por favor, abre un issue o pull request para sugerencias y mejoras.

## 📄 Licencia

Este proyecto está bajo la misma licencia que n8n.
