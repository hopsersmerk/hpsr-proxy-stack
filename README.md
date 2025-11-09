# Servidor Proxy con Docker y TLS/SSL

Servidor proxy HTTPS/SOCKS5 con autenticación, configurado para ejecutarse en tu VPS y permitirte navegar con la IP del servidor.

**✨ Características:**
- 🌐 **Proxy HTTPS** - Compatible con navegadores y Proxy SwitchyOmega
- 🔐 Autenticación por usuario/contraseña
- 🔒 Cifrado TLS/SSL con certificados de Let's Encrypt
- 🌍 Compatible con dominios personalizados (cualquier TLD: .com, .dev, .net, etc.)
- 🔄 Renovación automática de certificados
- 🚀 Fácil configuración con scripts automatizados
- 📦 Incluye también proxy SOCKS5 con Dante

## 🚀 Instalación y Configuración

### Opción A: Con SSL/TLS (Recomendado)

**Prerrequisitos:**
- Un dominio que apunte a tu servidor VPS (ej: `proxy.tudominio.com`, `proxy.tudominio.dev`, etc.)
- Puerto 80 y 443 abiertos en el firewall

**Pasos:**

1. **Ejecutar el script de setup:**
   ```bash
   sudo bash setup-ssl.sh
   ```
   El script te pedirá tu dominio (puede ser .com, .dev, .net, o cualquier TLD) y automáticamente:
   - Obtendrá certificados SSL de Let's Encrypt
   - Configurará stunnel con TLS
   - Configurará renovación automática

   **Nota:** Puedes usar cualquier dominio o subdominio que poseas, siempre que apunte a la IP de tu VPS.

2. **Configurar credenciales:**
   Edita `docker-compose.yml`:
   ```yaml
   environment:
     - PROXY_USER=tuusuario
     - PROXY_PASS=tucontraseña
   ```

3. **Iniciar servicios:**
   ```bash
   docker compose up -d
   ```

4. **Verificar:**
   ```bash
   docker logs -f stunnel-tls
   docker logs -f socks5-proxy
   ```

### Opción B: Sin SSL/TLS (Solo desarrollo)

**⚠️ No recomendado para producción - tráfico sin cifrar**

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

### Proxy HTTPS (Recomendado - Puerto 443)

**Desde tu PC o servidor:**
```bash
# Probar conexión HTTPS
curl --proxy https://proxyuser:changeme123@proxy.tudominio.com:443 https://ifconfig.me

# O con -k si tienes problemas con el certificado
curl -k --proxy https://proxyuser:changeme123@proxy.tudominio.com:443 https://ifconfig.me
```

**Resultado esperado:** Deberías ver la IP de tu VPS.

### Proxy SOCKS5 con SSH Tunnel (Alternativa)

Si prefieres usar SOCKS5:

1. **Crear túnel SSH:**
   ```bash
   ssh -N -L 1080:localhost:1080 usuario@proxy.tudominio.com
   ```

2. **Probar conexión:**
   ```bash
   curl --proxy socks5h://proxyuser:changeme123@localhost:1080 https://ifconfig.me
   ```

### Proxy SOCKS5 sobre TLS (Puerto 1443)

**Requiere cliente stunnel instalado en tu PC:**
```bash
curl --proxy socks5h://proxyuser:changeme123@proxy.tudominio.com:1443 https://ifconfig.me
```

**Nota:** Este método requiere configuración adicional de stunnel en el cliente.

## 🌐 Configurar en Navegadores

### ✅ Opción 1: Proxy HTTPS (Recomendado - Funciona Directamente)

#### Chrome/Edge con Proxy SwitchyOmega:
1. Instala la extensión **[Proxy SwitchyOmega](https://chrome.google.com/webstore/detail/proxy-switchyomega/padekgcemlokbadohgkifijomclgjgif)**
2. Clic en el ícono → **Options**
3. **New profile** → Nombre: `VPS Proxy` → **Proxy Profile**
4. Configuración:
   - **Protocol**: `HTTPS`
   - **Server**: `proxy.tudominio.com` (tu dominio)
   - **Port**: `443`
5. Expande **Authentication** (abajo):
   - **Username**: `proxyuser`
   - **Password**: `changeme123`
6. **Apply changes**
7. Clic en el ícono de SwitchyOmega → Selecciona `VPS Proxy`

🎉 **¡Listo!** Ahora todo tu tráfico irá por el proxy con SSL en el puerto 443.

#### Firefox con FoxyProxy:
1. Instala la extensión **[FoxyProxy](https://addons.mozilla.org/es/firefox/addon/foxyproxy-standard/)**
2. Clic en el ícono → **Options**
3. **Add** → **Manual Proxy Configuration**
4. Configuración:
   - **Title**: `VPS Proxy`
   - **Type**: `HTTP` (Firefox trata HTTPS como HTTP con auth)
   - **Hostname**: `proxy.tudominio.com`
   - **Port**: `443`
   - **Username**: `proxyuser`
   - **Password**: `changeme123`
5. **Save**
6. Activa el proxy desde el menú de FoxyProxy

### 🔧 Opción 2: Proxy SOCKS5 con SSH Tunnel

Si prefieres usar SOCKS5 con cifrado SSH:

1. **Crea un túnel SSH local** (deja esta terminal abierta):
   ```bash
   ssh -N -L 1080:localhost:1080 usuario@proxy.tudominio.com
   ```

2. **Configura el navegador:**
   - **Tipo**: `SOCKS5`
   - **Servidor**: `localhost`
   - **Puerto**: `1080`
   - **Usuario**: `proxyuser`
   - **Contraseña**: `changeme123`

**Ventaja:** Doble capa de cifrado (SSH + TLS)
**Desventaja:** Requiere mantener conexión SSH abierta

### Configuración del sistema (Linux):
```bash
# Con SSL/TLS
export ALL_PROXY=socks5h://proxyuser:changeme123@proxy.tudominio.com:443

# Sin SSL
export ALL_PROXY=socks5://proxyuser:changeme123@IP_DEL_VPS:443
```

## 🔒 Arquitectura y Seguridad

Este proyecto ofrece **dos tipos de proxy**:

### 1️⃣ Proxy HTTPS (Squid) - Puerto 443
```
┌─────────┐   HTTPS/SSL  ┌──────────┐
│ Cliente │─────────────▶│  Squid   │───▶ Internet
│  (tu PC)│   cifrado    │  (443)   │
└─────────┘              └──────────┘
```

**Ventajas:**
- ✅ Compatible nativamente con navegadores y extensiones
- ✅ Certificado válido de Let's Encrypt
- ✅ Parece tráfico HTTPS normal
- ✅ No requiere configuración adicional en el cliente
- ✅ Autenticación HTTP Basic integrada

**Uso ideal:**
- Proxy SwitchyOmega, FoxyProxy
- Configuración de proxy en navegadores
- Aplicaciones que soportan proxies HTTPS

### 2️⃣ Proxy SOCKS5 (Dante) - Puerto 1080 interno

Para uso con SSH tunnel o acceso directo:

```
┌─────────┐   SSH Tunnel ┌──────────┐   SOCKS5   ┌───────┐
│ Cliente │─────────────▶│   SSH    │───────────▶│ Dante │───▶ Internet
│  (tu PC)│   cifrado    │  (VPS)   │  interno   │(1080) │
└─────────┘              └──────────┘            └───────┘
```

**Para qué sirve el SSL:**
- Redes corporativas que bloquean proxies sin SSL
- ISPs que hacen inspección profunda de paquetes
- Países con censura que detectan y bloquean proxies
- Evitar que tu ISP sepa que usas un proxy

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

**Proxy HTTPS (Squid):**
- `squid.conf` → Configuración del proxy HTTPS con SSL
- `squid-passwd` → Archivo de contraseñas (generado automáticamente)
- `setup-squid-auth.sh` → Script para cambiar credenciales de Squid

**Proxy SOCKS5 (Dante):**
- `Dockerfile` → Imagen Docker con Dante SOCKS5
- `danted.conf` → Configuración del servidor Dante
- `entrypoint.sh` → Script que crea usuarios y arranca Dante
- `stunnel.conf` → Configuración de stunnel para SOCKS5+TLS

**General:**
- `docker-compose.yml` → Configuración de despliegue (Squid + Dante + stunnel)
- `setup-ssl.sh` → Script automatizado para obtener certificados SSL

## 🐛 Solución de Problemas

### Ver logs:
```bash
# Logs de Squid (proxy HTTPS)
docker logs -f squid-https

# Logs de Dante (proxy SOCKS5)
docker logs -f socks5-proxy

# Logs de stunnel (TLS para SOCKS5)
docker logs -f stunnel-tls

# Todos
docker compose logs -f
```

### El proxy no responde:
1. Verifica que los contenedores están corriendo:
   ```bash
   docker ps
   ```
2. Verifica el firewall del VPS:
   ```bash
   sudo ufw status
   # Deben estar abiertos los puertos 80 (para Let's Encrypt) y 443
   ```
3. Prueba localmente en el VPS primero
4. Si usas SSL, verifica que el dominio apunte al servidor:
   ```bash
   dig +short tudominio.com
   ```

### Problemas con certificados SSL:
1. **Error: "cert = /etc/letsencrypt/live/DOMAIN/fullchain.pem"**
   - No ejecutaste `setup-ssl.sh`
   - Solución: `sudo bash setup-ssl.sh`

2. **Error: "Certificate verify failed"**
   - El certificado expiró (después de 90 días)
   - Solución: Renovar manualmente:
     ```bash
     sudo certbot renew
     docker compose restart stunnel
     ```

3. **Error al obtener certificado:**
   - Verifica que el puerto 80 está abierto
   - Verifica que el dominio apunta al servidor
   - Temporalmente detén servicios: `docker compose down`

### Problemas de autenticación:
1. Verifica las credenciales en `docker-compose.yml`
2. Reconstruye la imagen:
   ```bash
   docker compose down
   docker compose build
   docker compose up -d
   ```

### Cambiar credenciales:
1. Edita `docker-compose.yml`
2. Reconstruye:
   ```bash
   docker compose up -d --force-recreate
   ```

### El navegador no se conecta con SSL:
- **Problema:** Los navegadores no soportan SOCKS5+TLS directamente
- **Solución:** Usa el proxy HTTPS (Squid) en puerto 443 o un túnel SSH local

### Verificar que SSL está funcionando:
```bash
# Verificar certificado SSL
openssl s_client -connect tudominio.com:443 -showcerts

# Deberías ver el certificado de Let's Encrypt

# Probar proxy HTTPS directamente
curl -k --proxy https://proxyuser:changeme123@tudominio.com:443 https://ifconfig.me
```

### Problemas con Squid (proxy HTTPS):

1. **Error 407 Proxy Authentication Required:**
   - Las credenciales son incorrectas
   - Verifica el archivo `squid-passwd`
   - Cambia credenciales: `sudo bash setup-squid-auth.sh`
   - Reinicia: `docker compose restart squid-https`

2. **Error de certificado SSL:**
   - Ejecuta: `sudo bash setup-ssl.sh`
   - Asegúrate de que el dominio apunta al servidor
   - Reinicia: `docker compose restart squid-https`

3. **Squid no arranca:**
   - Ver logs: `docker logs squid-https`
   - Verifica permisos: `ls -la squid-passwd squid.conf`
   - Verifica sintaxis: `docker exec squid-https squid -k parse`

### Probar conectividad paso a paso:

```bash
# 1. Verificar que Squid responde
curl -I http://proxy.tudominio.com:443

# 2. Probar autenticación (debe pedir credenciales)
curl --proxy https://proxy.tudominio.com:443 https://ifconfig.me

# 3. Probar con credenciales
curl --proxy https://proxyuser:changeme123@proxy.tudominio.com:443 https://ifconfig.me
```
