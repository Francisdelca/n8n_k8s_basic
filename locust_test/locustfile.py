from locust import HttpUser, task, between


class SimplePostUser(HttpUser):
    """
    Usuario simple que solo hace POST a un endpoint con un body.
    """
    
    # Espera entre 1 y 3 segundos entre peticiones
    wait_time = between(1, 3)
    
    @task
    def post_endpoint(self):
        """
        Tarea única: hacer POST al endpoint especificado.
        """
        # Body de la petición POST
        payload = {
            "message": "Hola desde Locust",
            "timestamp": "2024-01-01T12:00:00Z",
            "user_id": "test_user_123"
        }
        
        # Hacer la petición POST
        response = self.client.post("http://localhost:32205/webhook/pa-recopilador", json=payload)
        
        # Verificar la respuesta
        if response.status_code == 200:
            print("✅ POST exitoso")
        else:
            print(f"❌ Error: {response.status_code}")
