#!/bin/bash
set -e

echo "=================================================="
echo "  Configuración de Autenticación para Squid"
echo "=================================================="
echo ""

# Valores por defecto
DEFAULT_USER="proxyuser"
DEFAULT_PASS="changeme123"

# Verificar que se ejecuta como root
if [ "$EUID" -ne 0 ]; then
    echo "❌ Error: Este script debe ejecutarse como root o con sudo"
    echo "   Usa: sudo bash setup-squid-auth.sh"
    exit 1
fi

# Solicitar credenciales
echo "Configura las credenciales para el proxy HTTPS:"
read -p "Usuario [$DEFAULT_USER]: " PROXY_USER
PROXY_USER=${PROXY_USER:-$DEFAULT_USER}

read -sp "Contraseña [$DEFAULT_PASS]: " PROXY_PASS
echo ""
PROXY_PASS=${PROXY_PASS:-$DEFAULT_PASS}

echo ""
echo "📋 Configuración:"
echo "   Usuario: $PROXY_USER"
echo "   Contraseña: ********"
echo ""

# Instalar apache2-utils si no está disponible
if ! command -v htpasswd &> /dev/null; then
    echo "📦 Instalando apache2-utils para htpasswd..."
    apt-get update -qq
    apt-get install -y apache2-utils
fi

# Crear archivo de contraseñas
echo "🔐 Creando archivo de contraseñas..."
htpasswd -b -c squid-passwd "$PROXY_USER" "$PROXY_PASS"

echo ""
echo "✅ Archivo de contraseñas creado: squid-passwd"
echo ""
echo "Ahora puedes iniciar los servicios con:"
echo "  docker compose up -d"
echo ""
