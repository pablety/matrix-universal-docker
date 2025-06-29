#!/bin/bash

# Script de mantenimiento para Matrix Universal Docker
# Limpia logs, optimiza base de datos, verifica estado

set -e

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}🔧 Mantenimiento Matrix Universal Docker${NC}"
echo "========================================"

# Verificar que el contenedor está corriendo
if ! docker ps | grep -q "matrix-universal"; then
    echo -e "${RED}❌ El contenedor matrix-universal no está corriendo${NC}"
    exit 1
fi

echo -e "${BLUE}📅 Fecha: $(date)${NC}"
echo ""

# 1. Verificar estado de servicios
echo -e "${YELLOW}📋 Verificando estado de servicios...${NC}"
docker exec matrix-universal supervisorctl status
echo ""

# 2. Limpiar logs antiguos
echo -e "${YELLOW}🧹 Limpiando logs antiguos...${NC}"
docker exec matrix-universal bash -c "
    find /var/log -name '*.log.*' -type f -mtime +7 -delete 2>/dev/null || true
    find /var/log -name '*.gz' -type f -mtime +7 -delete 2>/dev/null || true
    echo 'Logs antiguos limpiados'
"
echo -e "${GREEN}✅ Logs limpiados${NC}"

# 3. Optimizar base de datos
echo -e "${YELLOW}🗄️  Optimizando base de datos PostgreSQL...${NC}"
docker exec matrix-universal sudo -u postgres psql -d synapse -c "
    VACUUM ANALYZE;
    REINDEX DATABASE synapse;
"
echo -e "${GREEN}✅ Base de datos optimizada${NC}"

# 4. Verificar espacio en disco
echo -e "${YELLOW}💾 Verificando espacio en disco...${NC}"
docker exec matrix-universal df -h
echo ""

# 5. Verificar conectividad Matrix
echo -e "${YELLOW}🔍 Verificando Matrix API...${NC}"
if curl -s --max-time 5 http://localhost:8008/_matrix/client/versions >/dev/null; then
    echo -e "${GREEN}✅ Matrix API funcionando${NC}"
else
    echo -e "${RED}❌ Matrix API no responde${NC}"
fi

# 6. Estadísticas de uso
echo -e "${YELLOW}📊 Estadísticas de uso...${NC}"
docker exec matrix-universal sudo -u postgres psql -d synapse -c "
    SELECT 
        'Usuarios registrados' as tipo,
        COUNT(*) as cantidad
    FROM users
    WHERE deactivated = 0
    UNION ALL
    SELECT 
        'Salas creadas' as tipo,
        COUNT(*) as