#!/bin/bash
set -e

# Asegurar directorio .ssh con permisos estrictos de Linux
mkdir -p /root/.ssh

# Si el volumen del host fue montado en /root/.ssh_host, copiar llaves y corregir permisos
if [ -d "/root/.ssh_host" ]; then
    cp -rf /root/.ssh_host/* /root/.ssh/ 2>/dev/null || true
    chmod 700 /root/.ssh 2>/dev/null || true
    chmod 600 /root/.ssh/* 2>/dev/null || true
    chmod 644 /root/.ssh/*.pub 2>/dev/null || true
fi

exec "$@"

