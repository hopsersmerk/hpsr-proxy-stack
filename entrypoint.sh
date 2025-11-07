#!/bin/bash
set -e

# Configurar usuario y contraseña para el proxy
PROXY_USER=${PROXY_USER:-proxyuser}
PROXY_PASS=${PROXY_PASS:-changeme123}

# Crear usuario del sistema si no existe
if ! id "$PROXY_USER" &>/dev/null; then
    echo "Creando usuario: $PROXY_USER"
    useradd -r -s /bin/false "$PROXY_USER"
    echo "$PROXY_USER:$PROXY_PASS" | chpasswd
fi

echo "Iniciando servidor SOCKS5..."
echo "Usuario configurado: $PROXY_USER"

# Iniciar dante en foreground
exec danted -f /etc/danted.conf -d 1
