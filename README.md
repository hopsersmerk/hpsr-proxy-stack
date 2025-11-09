# Proxy SOCKS5 con Docker y TLS/SSL

Servidor proxy SOCKS5 con autenticación basado en Dante, configurado para ejecutarse en tu VPS y permitirte navegar con la IP del servidor.

**✨ Características:**
- 🔐 Autenticación por usuario/contraseña
- 🔒 Cifrado TLS/SSL con certificados de Let's Encrypt
- 🌐 Compatible con dominios personalizados
- 🔄 Renovación automática de certificados
- 🚀 Fácil configuración con scripts automatizados

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

### Con SSL/TLS (si usaste setup-ssl.sh):

**Desde el servidor VPS:**
```bash
curl --proxy socks5h://proxyuser:changeme123@proxy.tudominio.com:443 https://ifconfig.me
```

**Desde tu PC:**
```bash
# Reemplaza proxy.tudominio.com con tu dominio
curl --proxy socks5h://proxyuser:changeme123@proxy.tudominio.com:443 https://ifconfig.me
```

**Nota:** Usa `socks5h://` (con 'h') para que el DNS se resuelva en el proxy, no en tu PC.

### Sin SSL/TLS (solo desarrollo):

**Desde el servidor VPS:**
```bash
curl --proxy socks5://proxyuser:changeme123@localhost:443 http://ifconfig.me
```

**Desde tu PC:**
```bash
curl --proxy socks5://proxyuser:changeme123@IP_DEL_VPS:443 http://ifconfig.me
```

**Resultado esperado:** Deberías ver la IP de tu VPS en lugar de tu IP local.

## 🌐 Configurar en Navegadores

### Firefox:
1. Instala la extensión **FoxyProxy**
2. Configuración → Añadir Proxy
3. Título: `Mi Proxy VPS`
4. Tipo: `SOCKS5`
5. Hostname: `proxy.tudominio.com` (o IP si no usas SSL)
6. Puerto: `443`
7. Usuario: `proxyuser`
8. Contraseña: `changeme123`

⚠️ **Nota sobre SSL/TLS:** Los navegadores no pueden conectarse directamente a SOCKS5+TLS. Necesitas:
- **Opción 1:** Usar el proxy con `curl` o aplicaciones de terminal
- **Opción 2:** Crear un túnel SSH local (ver sección abajo)
- **Opción 3:** Usar extensiones que soporten stunnel client-side

### Chrome/Edge con Proxy SwitchyOmega:
1. Instala la extensión **Proxy SwitchyOmega**
2. Nuevo perfil → Tipo: `SOCKS5`
3. Servidor: `proxy.tudominio.com` (o IP)
4. Puerto: `443`
5. Usuario: `proxyuser`
6. Contraseña: `changeme123`

**Mismo problema SSL/TLS:** Ver soluciones arriba.

### Solución: Túnel SSH Local (Recomendado para navegadores)

Si quieres usar el proxy con SSL en navegadores, crea un túnel SSH local:

```bash
# En tu PC, crea un túnel local
ssh -L 1080:localhost:443 usuario@tu-vps.com

# Ahora configura el navegador para usar:
# Servidor: localhost
# Puerto: 1080
# Tipo: SOCKS5
```

Esto crea un túnel cifrado SSH que reenvía al proxy con SSL.

### Configuración del sistema (Linux):
```bash
# Con SSL/TLS
export ALL_PROXY=socks5h://proxyuser:changeme123@proxy.tudominio.com:443

# Sin SSL
export ALL_PROXY=socks5://proxyuser:changeme123@IP_DEL_VPS:443
```

## 🔒 ¿Cómo funciona el SSL/TLS con SOCKS5?

SOCKS5 por sí mismo **NO tiene soporte nativo para TLS/SSL**. Sin embargo, este proyecto usa **stunnel** para tunelizar el tráfico SOCKS5 sobre TLS:

```
┌─────────┐   TLS/SSL    ┌──────────┐   SOCKS5   ┌───────┐
│ Cliente │─────────────▶│ stunnel  │───────────▶│ Dante │───▶ Internet
│  (tu PC)│   cifrado    │ (puerto  │  sin cifrar│(proxy)│
└─────────┘   (443)      │   443)   │  (interno) └───────┘
                         └──────────┘
```

**Ventajas:**
- ✅ Conexión cifrada de extremo a extremo hasta el proxy
- ✅ Certificado válido de Let's Encrypt (evita advertencias)
- ✅ Parece tráfico HTTPS normal (bypass firewalls)
- ✅ Protege contra inspección de paquetes (DPI)

**Para qué sirve:**
- Redes corporativas que bloquean proxies sin SSL
- ISPs que hacen inspección profunda de paquetes
- Países con censura que detectan y bloquean SOCKS5
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

- `Dockerfile` → Imagen Docker con Dante SOCKS5
- `docker-compose.yml` → Configuración de despliegue (Dante + stunnel)
- `danted.conf` → Configuración del servidor Dante
- `entrypoint.sh` → Script que crea usuarios y arranca Dante
- `stunnel.conf` → Configuración de stunnel para TLS
- `setup-ssl.sh` → Script automatizado para obtener certificados SSL

## 🐛 Solución de Problemas

### Ver logs:
```bash
# Logs de stunnel (TLS)
docker logs -f stunnel-tls

# Logs de Dante (SOCKS5)
docker logs -f socks5-proxy

# Ambos
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
- **Solución:** Usa un túnel SSH local (ver sección "Configurar en Navegadores")

### Verificar que SSL está funcionando:
```bash
# Desde tu PC
openssl s_client -connect tudominio.com:443 -showcerts

# Deberías ver el certificado de Let's Encrypt
```
