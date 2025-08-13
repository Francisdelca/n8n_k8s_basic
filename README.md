# n8n en Kubernetes

Este repositorio contiene configuraciones de Helm para desplegar n8n en Kubernetes, con configuraciones optimizadas para desarrollo local y producción.

## 📁 Archivos de Configuración

### 1. `values.yaml` - Configuración Local (Desarrollo)
- **Uso**: Desarrollo local con acceso interno del cluster
- **Servicio**: NodePort (puerto 5678)
- **Base de datos**: PostgreSQL y Redis externos (Docker)
- **Versión**: Última versión estable de n8n
- **Características**: Configuración simple, autoscaling básico

### 2. `values-prod.yaml` - Configuración de Producción
- **Uso**: Entorno de producción con alta disponibilidad
- **Servicio**: ClusterIP + Ingress con SSL
- **Base de datos**: PostgreSQL y Redis gestionados en K8s
- **Versión**: Última versión estable de n8n
- **Características**: SSL, autoscaling, múltiples réplicas, seguridad robusta

## 🚀 Instalación Rápida

### Usando Make (Recomendado)

```bash
# Ver todos los comandos disponibles
make help

# Configurar entorno de desarrollo
make dev-setup

# Instalar n8n local
make install-local

# Ver estado
make status

# Ver logs
make logs

# Port-forward para acceso local
make port-forward
```

### Para Producción

```bash
# Configurar entorno de producción
make prod-setup

# Editar .env con tus valores reales
nano .env

# Validar configuración
make validate-env

# Instalar n8n en producción
make install-prod
```

## 🔧 Configuración con Variables de Entorno

### 1. Configurar Variables

```bash
# Copiar archivo de ejemplo
cp env.example .env

# Editar con tus valores reales
nano .env
```

### 2. Variables Críticas a Configurar

```bash
# Dominio y SSL
N8N_DOMAIN=n8n.tudominio.com
N8N_EMAIL=tu-email@tudominio.com

# Base de datos
DB_PASSWORD=tu-password-postgres-seguro
REDIS_PASSWORD=tu-password-redis-seguro

# Seguridad
N8N_ENCRYPTION_KEY=tu-clave-de-32-caracteres
N8N_ADMIN_PASSWORD=tu-password-admin-seguro

# Storage
STORAGE_CLASS=fast-ssd
```

### 3. Generar Configuración

```bash
# Generar values-prod.yaml desde .env
make generate-prod

# O manualmente
./generate-prod-config.sh
```

## 🗄️ Bases de Datos

### Para Desarrollo Local

#### PostgreSQL
```bash
docker run --name postgres-n8n \
  -e POSTGRES_PASSWORD=441377 \
  -e POSTGRES_USER=n8n \
  -e POSTGRES_DB=n8n \
  -p 5432:5432 \
  -d postgres:15
```

#### Redis
```bash
docker run --name redis-n8n \
  -e REDIS_PASSWORD=441377 \
  -p 6379:6379 \
  -d redis:7-alpine
```

### Para Producción
- Usar servicios gestionados (AWS RDS, GCP Cloud SQL, Azure Database)
- O crear deployments separados de PostgreSQL y Redis en el cluster

## ⚙️ Configuración Manual

### Variables Importantes a Cambiar

#### En `values-prod.yaml`:
- `n8n.tudominio.com` → Tu dominio real
- `your-32-character-encryption-key-here` → Clave de encriptación segura
- `tu-password-postgres-seguro` → Contraseña PostgreSQL segura
- `tu-password-redis-seguro` → Contraseña Redis segura
- `tu-password-admin-seguro` → Contraseña de administrador
- `fast-ssd` → Tu storage class de producción

#### En `values.yaml`:
- `microk8s-hostpath` → Tu storage class local
- Contraseñas de base de datos (opcional para desarrollo)

### Storage Classes

#### MicroK8s
```bash
microk8s enable storage
# Usar: microk8s-hostpath
```

#### Minikube
```bash
# Usar: standard
```

#### Otros clusters
```bash
kubectl get storageclass
# Usar el que corresponda a tu cluster
```

## 🔒 Seguridad

### Para Desarrollo
- Autenticación básica deshabilitada
- Logs en modo debug
- Recursos mínimos
- Acceso directo sin SSL

### Para Producción
- Autenticación básica habilitada
- SSL/TLS obligatorio
- Logs en modo info
- Recursos limitados y requests
- Pods ejecutándose como usuario no-root
- Clave de encriptación configurada

## 📊 Monitoreo y Gestión

### Comandos Útiles

```bash
# Ver estado completo
make status

# Ver logs en tiempo real
make logs

# Port-forward para acceso local
make port-forward

# Desinstalar
make uninstall-local    # Para desarrollo
make uninstall-prod     # Para producción

# Limpiar archivos generados
make clean
```

### Ver Estado Manual

```bash
# Ver pods
kubectl get pods

# Ver servicios
kubectl get svc

# Ver ingress (solo producción)
kubectl get ingress

# Ver eventos
kubectl get events --sort-by=.metadata.creationTimestamp
```

## 🔄 Actualizaciones

### Actualizar n8n
```bash
# Cambiar tag en values.yaml
helm upgrade n8n-local . -f values.yaml
```

### Actualizar configuración
```bash
# Aplicar cambios en values
helm upgrade n8n-local . -f values.yaml
```

## 🗑️ Desinstalación

```bash
# Desinstalar release
make uninstall-local

# Limpiar PVCs (opcional)
kubectl delete pvc -l app.kubernetes.io/instance=n8n-local
```

## 🐛 Troubleshooting

### Problemas Comunes

#### Pod no inicia
```bash
# Ver detalles del pod
kubectl describe pod <pod-name>

# Ver logs
kubectl logs <pod-name>
```

#### Problemas de conectividad a base de datos
- Verificar que PostgreSQL y Redis estén corriendo
- Verificar credenciales en secrets
- Verificar configuración de red

#### Problemas de persistencia
- Verificar storage class disponible
- Verificar permisos de PVC

### Validar Configuración

```bash
# Validar variables de entorno
make validate-env

# Ver estado del deployment
make status
```

## 📚 Recursos Adicionales

- [Documentación oficial de n8n](https://docs.n8n.io/)
- [Chart de Helm n8n](https://github.com/8gears/n8n-helm-chart)
- [Documentación de Kubernetes](https://kubernetes.io/docs/)
- [Documentación de Helm](https://helm.sh/docs/)

## 🤝 Contribuciones

Las contribuciones son bienvenidas. Por favor:

1. Fork el repositorio
2. Crea una rama para tu feature
3. Commit tus cambios
4. Push a la rama
5. Abre un Pull Request

## 📄 Licencia

Este proyecto está bajo la licencia MIT.