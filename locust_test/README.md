# Prueba de Carga Básica con Locust

Proyecto minimalista para hacer pruebas de carga con Locust.

## ¿Qué hace?

Simplemente ejecuta peticiones POST a un endpoint con un body JSON.

## Instalación

```bash
pip install -r requirements.txt
```

## Uso

### 1. Modificar el endpoint y body

Edita `locustfile.py` y cambia:
- La URL del endpoint (por defecto: `/api/test`)
- El body de la petición POST

### 2. Ejecutar la prueba

```bash
# Con interfaz web
locust -f locustfile.py --host=http://tu-servidor.com

# Desde línea de comandos
locust -f locustfile.py --host=http://tu-servidor.com --users=10 --spawn-rate=2 --run-time=60s --headless
```

### 3. Configurar en la interfaz web

- Abre http://localhost:8089
- Configura el número de usuarios
- Haz clic en "Start swarming"

## Personalización

Para cambiar el endpoint o el body, modifica estas líneas en `locustfile.py`:

```python
# Cambiar el endpoint
response = self.client.post("/tu-endpoint", json=payload)

# Cambiar el body
payload = {
    "tu_campo": "tu_valor",
    "otro_campo": "otro_valor"
}
```
