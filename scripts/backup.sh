#!/bin/bash

# Script de backup para Matrix Universal Docker
# Hace backup de: datos Matrix, base de datos PostgreSQL, certificados SSL

set -e

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}💾 Backup Matrix Universal Docker${NC}"
echo "=================================="

# Configuración
BACKUP_DIR="./backups"
DATE=$(date +'%Y%m%d_%H%M%S')
BACKUP_NAME="matrix_backup_$DATE"
BACKUP_PATH="$BACKUP_DIR/$BACKUP_NAME"

# Crear directorio de backup
mkdir -p "$BACKUP_PATH"

echo -e "${BLUE}📅 Backup: $BACKUP_NAME${NC}"
echo -e "${BLUE}📁 Destino: $BACKUP_PATH${NC}"

# Verificar que el contenedor está corriendo
if ! docker ps | grep -q "matrix-universal"; then
    echo -e "${RED}❌ El contenedor matrix-universal no está corriendo${NC}"
    exit 1
fi

# 1. Backup de datos Matrix
echo -e "${YELLOW}📦 Respaldando datos Matrix...${NC}"
docker exec matrix-universal tar -czf /tmp/matrix_data.tar.gz -C /opt/matrix data homeserver.yaml homeserver.log.config
docker cp matrix-universal:/tmp/matrix_data.tar.gz "$BACKUP_PATH/"
docker exec matrix-universal rm /tmp/matrix_data.tar.gz
echo -e "${GREEN}✅ Datos Matrix respaldados${NC}"

# 2. Backup de base de datos PostgreSQL
echo -e "${YELLOW}🗄️  Respaldando base de datos PostgreSQL...${NC}"
docker exec matrix-universal sudo -u postgres pg_dump synapse > "$BACKUP_PATH/postgres_synapse.sql"
echo -e "${GREEN}✅ Base de datos PostgreSQL respaldada${NC}"

# 3. Backup de certificados SSL
echo -e "${YELLOW}🔐 Respaldando certificados SSL...${NC}"
docker exec matrix-universal tar -czf /tmp/ssl_certs.tar.gz -C /etc/ssl matrix
docker cp matrix-universal:/tmp/ssl_certs.tar.gz "$BACKUP_PATH/"
docker exec matrix-universal rm /tmp/ssl_certs.tar.gz
echo -e "${GREEN}✅ Certificados SSL respaldados${NC}"

# 4. Backup de configuración
echo -e "${YELLOW}⚙️  Respaldando configuración...${NC}"
cp docker-compose.yml "$BACKUP_PATH/" 2>/dev/null || true
cp .env "$BACKUP_PATH/" 2>/dev/null || true
cp -r scripts "$BACKUP_PATH/" 2>/dev/null || true
cp -r configs "$BACKUP_PATH/" 2>/dev/null || true
echo -e "${GREEN}✅ Configuración respaldada${NC}"

# 5. Crear archivo de información
cat > "$BACKUP_PATH/backup_info.txt" << EOF
Matrix Universal Docker - Backup Information
===========================================
Backup Date: $(date)
Backup Name: $BACKUP_NAME
Container Name: matrix-universal

Files Included:
- matrix_data.tar.gz (Matrix data, config, logs)
- postgres_synapse.sql (PostgreSQL database dump)
- ssl_certs.tar.gz (SSL certificates)
- docker-compose.yml (Docker configuration)
- .env (Environment variables)
- scripts/ (Utility scripts)
- configs/ (Configuration templates)

Restore Instructions:
1. Stop current container: docker-compose down
2. Restore data: tar -xzf matrix_data.tar.gz -C ./data/matrix/
3. Restore database: docker exec matrix-universal psql -U synapse_user -d synapse < postgres_synapse.sql
4. Restore SSL: tar -xzf ssl_certs.tar.gz -C ./data/ssl/
5. Start container: docker-compose up -d

System Information:
- Host: $(hostname)
- User: $(whoami)
- Docker Version: $(docker --version)
- Backup Size: $(du -sh "$BACKUP_PATH" | cut -f1)
EOF

# 6. Comprimir todo el backup
echo -e "${YELLOW}📦 Comprimiendo backup...${NC}"
cd "$BACKUP_DIR"
tar -czf "$BACKUP_NAME.tar.gz" "$BACKUP_NAME/"
rm -rf "$BACKUP_NAME"
cd ..

BACKUP_SIZE=$(du -sh "$BACKUP_DIR/$BACKUP_NAME.tar.gz" | cut -f1)

echo ""
echo -e "${GREEN}✅ Backup completado exitosamente${NC}"
echo -e "${BLUE}📋 Información del backup:${NC}"
echo "   📁 Archivo: $BACKUP_DIR/$BACKUP_NAME.tar.gz"
echo "   📏 Tamaño: $BACKUP_SIZE"
echo "   📅 Fecha: $(date)"
echo ""
echo -e "${YELLOW}🔄 Para restaurar este backup:${NC}"
echo "   1. Extrae: tar -xzf $BACKUP_DIR/$BACKUP_NAME.tar.gz"
echo "   2. Sigue las instrucciones en backup_info.txt"
echo ""
echo -e "${BLUE}💡 Tip: Guarda este archivo en un lugar seguro${NC}"