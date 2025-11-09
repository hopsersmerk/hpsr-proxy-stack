#!/bin/bash
set -e

echo "=================================================="
echo "  Setup de Certificado SSL para Proxy SOCKS5"
echo "=================================================="
echo ""

# Verificar que se ejecuta como root
if [ "$EUID" -ne 0 ]; then
    echo "❌ Error: Este script debe ejecutarse como root o con sudo"
    echo "   Usa: sudo bash setup-ssl.sh"
    exit 1
fi

# Solicitar dominio
echo "Ingresa tu dominio completo (ej: proxy.tudominio.com, proxy.tudominio.dev, etc.):"
read -p "Dominio: " DOMAIN

if [ -z "$DOMAIN" ]; then
    echo "❌ Error: Debes ingresar un dominio"
    exit 1
fi

echo ""
echo "📋 Configuración:"
echo "   Dominio: $DOMAIN"
echo ""

# Verificar resolución DNS
echo "🔍 Verificando DNS..."
SERVER_IP=$(curl -s https://api.ipify.org)
DOMAIN_IP=$(dig +short "$DOMAIN" | tail -n1)

echo "   IP del servidor: $SERVER_IP"
echo "   IP del dominio:  $DOMAIN_IP"

if [ "$SERVER_IP" != "$DOMAIN_IP" ]; then
    echo ""
    echo "⚠️  ADVERTENCIA: El dominio NO apunta a este servidor!"
    echo "   Asegúrate de configurar un registro A en tu DNS:"
    echo "   $DOMAIN → $SERVER_IP"
    echo ""
    read -p "¿Continuar de todos modos? (y/N): " CONTINUE
    if [[ ! "$CONTINUE" =~ ^[Yy]$ ]]; then
        echo "❌ Abortado"
        exit 1
    fi
fi

# Instalar certbot si no está instalado
if ! command -v certbot &> /dev/null; then
    echo ""
    echo "📦 Instalando certbot..."
    apt-get update -qq
    apt-get install -y certbot python3-certbot-dns-cloudflare 2>/dev/null || apt-get install -y certbot
fi

# Detener servicios que puedan usar el puerto 80
echo ""
echo "🛑 Deteniendo servicios que puedan usar puerto 80..."
docker compose down 2>/dev/null || true
systemctl stop nginx 2>/dev/null || true
systemctl stop apache2 2>/dev/null || true

# Obtener certificado
echo ""
echo "🔐 Obteniendo certificado de Let's Encrypt..."
echo "   Esto puede tomar un minuto..."
echo ""

certbot certonly --standalone \
    --preferred-challenges http \
    --agree-tos \
    --register-unsafely-without-email \
    -d "$DOMAIN" || {
        echo ""
        echo "❌ Error al obtener el certificado"
        echo "   Verifica que:"
        echo "   1. El dominio $DOMAIN apunta a $SERVER_IP"
        echo "   2. El puerto 80 está abierto en el firewall"
        echo "   3. No hay otros servicios usando el puerto 80"
        exit 1
    }

# Actualizar stunnel.conf con el dominio
echo ""
echo "📝 Configurando stunnel..."
# Reemplazar {DOMAIN} placeholder con el dominio real
sed -i "s|{DOMAIN}|$DOMAIN|g" stunnel.conf
# Por si acaso ya tiene un dominio configurado, también reemplazar el path completo
sed -i "s|/etc/letsencrypt/live/[^/{}]*/|/etc/letsencrypt/live/$DOMAIN/|g" stunnel.conf

echo ""
echo "✅ Certificado obtenido exitosamente!"
echo ""
echo "📋 Información del certificado:"
certbot certificates -d "$DOMAIN"
echo ""

# Configurar renovación automática
echo "🔄 Configurando renovación automática..."
COMPOSE_DIR=$(pwd)
# Eliminar cron job anterior si existe
(crontab -l 2>/dev/null | grep -v "certbot renew") | crontab - 2>/dev/null || true
# Agregar nuevo cron job
(crontab -l 2>/dev/null; echo "0 0 * * * certbot renew --quiet --deploy-hook 'cd $COMPOSE_DIR && docker compose restart stunnel-tls'") | crontab -

echo ""
echo "=================================================="
echo "✅ ¡Configuración completada!"
echo "=================================================="
echo ""
echo "Ahora ejecuta:"
echo "  docker compose up -d"
echo ""
echo "Para probar la conexión:"
echo "  curl --proxy socks5h://proxyuser:changeme123@$DOMAIN:443 https://ifconfig.me"
echo ""
echo "Nota: El certificado se renovará automáticamente cada 90 días"
echo ""
