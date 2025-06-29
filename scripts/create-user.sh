#!/bin/bash

# Script para crear usuarios Matrix fácilmente
# Uso: ./scripts/create-user.sh [username] [password] [admin]

set -e

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}👤 Creador de usuarios Matrix Universal${NC}"
echo "========================================"

# Verificar si el contenedor está corriendo
if ! docker ps | grep -q "matrix-universal"; then
    echo -e "${RED}❌ El contenedor matrix-universal no está corriendo${NC}"
    echo "Ejecuta: docker-compose up -d"
    exit 1
fi

# Parámetros
USERNAME="$1"
PASSWORD="$2"
IS_ADMIN="$3"

# Pedir datos si no se proporcionaron
if [ -z "$USERNAME" ]; then
    echo -e "${YELLOW}Ingresa el nombre de usuario:${NC}"
    read -r USERNAME
fi

if [ -z "$PASSWORD" ]; then
    echo -e "${YELLOW}Ingresa la contraseña:${NC}"
    read -s PASSWORD
    echo
fi

if [ -z "$IS_ADMIN" ]; then
    echo -e "${YELLOW}¿Es administrador? (y/N):${NC}"
    read -r IS_ADMIN
fi

# Validar datos
if [ -z "$USERNAME" ] || [ -z "$PASSWORD" ]; then
    echo -e "${RED}❌ Username y password son requeridos${NC}"
    exit 1
fi

# Configurar parámetros para el comando
ADMIN_FLAG=""
if [[ "$IS_ADMIN" =~ ^[Yy]$ ]]; then
    ADMIN_FLAG="--admin"
    echo -e "${YELLOW}⚠️  Creando usuario administrador${NC}"
fi

echo -e "${BLUE}📝 Creando usuario: $USERNAME${NC}"

# Ejecutar comando en el contenedor
if docker exec -it matrix-universal bash -c "
    sudo -u matrix /opt/matrix/env/bin/register_new_matrix_user \
        -c /opt/matrix/homeserver.yaml \
        -u '$USERNAME' \
        -p '$PASSWORD' \
        $ADMIN_FLAG \
        --no-config \
        http://localhost:8008
"; then
    echo ""
    echo -e "${GREEN}✅ Usuario creado exitosamente${NC}"
    echo -e "${BLUE}📋 Información del usuario:${NC}"
    echo "   👤 Username: $USERNAME"
    echo "   🔐 Password: [oculto]"
    echo "   👑 Admin: $([ -n "$ADMIN_FLAG" ] && echo "Sí" || echo "No")"
    echo ""
    echo -e "${YELLOW}🌐 Acceso a Matrix:${NC}"
    echo "   https://localhost"
    echo "   http://localhost"
else
    echo -e "${RED}❌ Error al crear el usuario${NC}"
    echo "Verifica los logs: docker-compose logs matrix-universal"
    exit 1
fi