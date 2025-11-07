# Proxy SOCKS5 con Docker

Servidor proxy SOCKS5 con autenticación basado en Dante, configurado para ejecutarse en tu VPS y permitirte navegar con la IP del servidor.

## 🚀 Instalación y Configuración

### 1. Configurar credenciales

Edita el archivo `docker-compose.yml` y cambia las credenciales por defecto:

```yaml
environment:
  - PROXY_USER=tuusuario
  - PROXY_PASS=tucontraseña
```

### 2. Construir e iniciar el proxy

```bash
docker compose build
docker compose up -d
```

### 3. Verificar que está funcionando

```bash
docker logs -f socks5-proxy
```

Deberías ver: `Iniciando servidor SOCKS5...`

## 🧪 Probar el Proxy

### Desde el servidor VPS:

```bash
curl --proxy socks5://proxyuser:changeme123@localhost:443 http://ifconfig.me
```

### Desde tu PC (reemplaza IP_DEL_VPS con la IP de tu servidor):

```bash
curl --proxy socks5://proxyuser:changeme123@IP_DEL_VPS:443 http://ifconfig.me
```

Deberías ver la IP de tu VPS en lugar de tu IP local.

## 🌐 Configurar en Navegadores

### Firefox:
1. Configuración → General → Configuración de red → Configuración
2. Selecciona "Configuración manual del proxy"
3. Servidor SOCKS: `IP_DEL_VPS`
4. Puerto: `443`
5. Marca "SOCKS v5"
6. ⚠️ **Importante**: Firefox no soporta autenticación SOCKS nativamente. Usa una extensión como FoxyProxy o configura SSH tunnel.

### Chrome/Edge (Windows):
Usa una extensión como Proxy SwitchyOmega:
1. Instala la extensión
2. Nuevo perfil → Tipo: SOCKS5
3. Servidor: `IP_DEL_VPS`
4. Puerto: `443`
5. Usuario: `proxyuser`
6. Contraseña: `changeme123`

### Configuración del sistema (Linux):
```bash
export ALL_PROXY=socks5://proxyuser:changeme123@IP_DEL_VPS:443
```

## 🔐 Seguridad

✅ **Incluye autenticación por usuario/contraseña**
- Usuario por defecto: `proxyuser`
- Contraseña por defecto: `changeme123`
- ⚠️ **CAMBIA ESTAS CREDENCIALES** en `docker-compose.yml`

### Firewall (Opcional pero recomendado):

Limita el acceso solo desde tu IP:

```bash
# UFW (Ubuntu/Debian)
sudo ufw allow from TU_IP_PERSONAL to any port 443

# iptables
sudo iptables -A INPUT -p tcp -s TU_IP_PERSONAL --dport 443 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 443 -j DROP
```

## 📂 Archivos del Proyecto

- `Dockerfile` → Imagen Docker con Dante SOCKS5
- `docker-compose.yml` → Configuración de despliegue
- `danted.conf` → Configuración del servidor Dante
- `entrypoint.sh` → Script que crea usuarios y arranca el servicio

## 🐛 Solución de Problemas

### Ver logs:
```bash
docker logs -f socks5-proxy
```

### El proxy no responde:
1. Verifica que el contenedor está corriendo: `docker ps`
2. Verifica el firewall del VPS: `sudo ufw status`
3. Prueba localmente en el VPS primero

### Problemas de autenticación:
1. Verifica las credenciales en `docker-compose.yml`
2. Reconstruye la imagen: `docker compose down && docker compose build && docker compose up -d`

### Cambiar credenciales:
1. Edita `docker-compose.yml`
2. Reconstruye: `docker compose up -d --force-recreate`
