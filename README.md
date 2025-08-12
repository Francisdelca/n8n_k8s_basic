# Despliegue de n8n en Kubernetes

## Prerrequisitos

* **kubectl** - [Instalar kubectl](https://kubernetes.io/es/docs/tasks/tools/)
* **helm** - [Instalar helm](https://helm.sh/docs/intro/install/)
* **microk8s** (Desarrollo) - [Instalar microk8s](https://microk8s.io/)

## 1. Despliegue usando Helm

### Chart de Helm
Utilizamos el chart oficial de n8n disponible en [Artifact Hub](https://artifacthub.io/packages/helm/open-8gears/n8n).

### Configuración para Desarrollo

Crea un archivo `values.yaml` con la siguiente configuración:

```yaml
# Configuración del servicio de n8n
main:
  service:
    type: ClusterIP
    port: 5678

config:
  DB_TYPE: "postgresdb"
  DB_POSTGRESDB_HOST: "host.docker.internal"
  DB_POSTGRESDB_DATABASE: "n8n"
  DB_POSTGRESDB_USER: "n8n"
  GENERIC_HOST: "localhost:5678"
  N8N_HOST: "localhost:5678"
  N8N_PROTOCOL: "http"
  REDIS_HOST: "host.docker.internal"
  REDIS_PORT: 6379

secret:
  DB_POSTGRESDB_PASSWORD: "my-secret-password" # ¡Cámbialo!
  REDIS_PASSWORD: "my-redis-password" # ¡Cámbialo!

persistence:
  enabled: true
  size: 10Gi
  accessMode: ReadWriteOnce
  storageClass: "microk8s-hostpath"
```

### Instalación con Helm

```bash
helm install my-n8n oci://8gears.container-registry.com/library/n8n --version 1.0.0
```

### Configuración para Producción

Para entornos de producción, utiliza esta configuración más robusta:

```yaml
main:
  service:
    type: ClusterIP
    port: 5678
  
  config:
    DB_TYPE: "postgresdb"
    DB_POSTGRESDB_HOST: "aqui-va-el-hostname-de-tu-rds..."
    DB_POSTGRESDB_DATABASE: "n8n"
    DB_POSTGRESDB_USER: "n8n"
    DB_POSTGRESDB_PORT: 5432
    REDIS_HOST: "aqui-va-el-hostname-de-tu-elasticache..."
    REDIS_PORT: 6379
  
  secret:
    DB_POSTGRESDB_PASSWORD: "aqui-va-la-contrasena-segura-de-rds"
    REDIS_PASSWORD: "aqui-va-la-contrasena-segura-de-redis"

postgresql:
  enabled: false

redis:
  enabled: false

ingress:
  enabled: true
  className: "nginx"
  annotations:
    kubernetes.io/ingress.class: nginx
    cert-manager.io/cluster-issuer: "letsencrypt-staging"
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
  hosts:
    - host: "n8n.tu-dominio.com"
      paths:
        - path: /
          pathType: Prefix
          serviceName: n8n-n8n
          servicePort: 5678
```

## 2. Instalación de Ingress Controller y Cert-Manager

El Ingress Controller gestionará el tráfico externo, mientras que Cert-Manager obtendrá certificados SSL/TLS automáticamente para habilitar HTTPS.

### Agregar repositorio de Helm

```bash
helm repo add jetstack https://charts.jetstack.io
helm repo update
```

### Instalar Cert-Manager

```bash
helm install cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --version v1.15.1 \
  --set installCRDs=true
```

## 3. Configuración del ClusterIssuer

Crea un archivo `letsencrypt-issuer.yaml` que le indica a Cert-Manager cómo solicitar certificados a Let's Encrypt:

```yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-staging
spec:
  acme:
    email: tu-email@dominio.com
    server: https://acme-staging-v02.api.letsencrypt.org/directory
    privateKeySecretRef:
      name: letsencrypt-staging
    solvers:
      - http01:
          ingress:
            class: nginx
```

### Aplicar el ClusterIssuer

```bash
kubectl apply -f letsencrypt-issuer.yaml
```

## 4. Despliegue de n8n y Configuración de DNS

### Instalación de n8n

```bash
helm install n8n oci://8gears.container-registry.com/library/n8n \
  --version 1.0.10 \
  -f n8n-production-values.yaml
```

### Configuración de DNS

> [!INFO]
> **Acción Requerida:** Configurar DNS
> 
> 1. Obtén la IP externa del Ingress:
>    ```bash
>    kubectl get services -n default
>    ```
> 
> 2. Ve a tu proveedor de DNS (ej. Amazon Route 53) y crea un registro `A` que apunte `n8n.tu-dominio.com` a esa IP.

## 5. Configuración de Autoescalado (HPA)

Para que n8n pueda manejar picos de tráfico, configuraremos un Horizontal Pod Autoscaler (HPA). Este componente de Kubernetes creará o eliminará réplicas de n8n automáticamente según el uso de CPU.

### Crear el HPA

```bash
kubectl autoscale deployment/n8n-n8n \
  --cpu-percent=70 \
  --min=2 \
  --max=10
```

El HPA mantendrá un mínimo de 2 réplicas para alta disponibilidad y escalará hasta un máximo de 10 según la utilización de CPU.