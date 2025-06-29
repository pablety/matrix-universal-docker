#!/bin/bash

# Matrix Universal Docker - Script de construcción e instalación
# Creado por: pablety
# Fecha: 2025-06-29
# Uso: ./build-and-run.sh

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Funciones de logging
log() { echo -e "${BLUE}[$(date +'%H:%M:%S')]${NC} $1"; }
log_success() { echo -e "${GREEN}[$(date +'%H:%M:%S')] ✓${NC} $1"; }
log_warning() { echo -e "${YELLOW}[$(date +'%H:%M:%S')] ⚠${NC} $1"; }
log_error() { echo -e "${RED}[$(date +'%H:%M:%S')] ✗${NC} $1"; }
log_info() { echo -e "${CYAN}[$(date +'%H:%M:%S')] ℹ${NC} $1"; }

# Banner
echo -e "${GREEN}"
cat << "EOF"
╔════════════════════════════════════════════════════════════════╗
║                                                                ║
║           Matrix Universal Docker Builder v1.0                ║
║                                                                ║
║    🚀 Funciona en cualquier equipo con Docker                 ║
║    📦 PostgreSQL + Matrix Synapse + Element Web               ║
║    🔐 HTTPS automático con certificados                       ║
║    💾 Datos persistentes                                       ║
║                                                                ║
╚════════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

# Detectar sistema
OS=$(uname -s)
ARCH=$(uname -m)
log_info "Sistema: $OS ($ARCH)"
log_info "Usuario: $(whoami)"
log_info "Directorio: $(pwd)"

# Verificar Docker
if ! command -v docker >/dev/null 2>&1; then
    log_error "Docker no está instalado"
    log_info "Instala Docker desde: https://docs.docker.com/get-docker/"
    exit 1
fi

if ! command -v docker-compose >/dev/null 2>&1; then
    log_error "Docker Compose no está instalado"
    log_info "Instala Docker Compose desde: https://docs.docker.com/compose/install/"
    exit 1
fi

log_success "Docker encontrado: $(docker --version)"
log_success "Docker Compose encontrado: $(docker-compose --version)"

# Verificar permisos Docker
if ! docker info >/dev/null 2>&1; then
    log_error "No tienes permisos para usar Docker"
    log_info "Ejecuta: sudo usermod -aG docker $(whoami)"
    log_info "Y luego: newgrp docker"
    exit 1
fi

# Detectar IP local
detect_ip() {
    local ip=""
    
    # Método 1: IP hacia internet
    ip=$(ip route get 8.8.8.8 2>/dev/null | grep -oP 'src \K\S+' || true)
    
    # Método 2: hostname -I
    if [ -z "$ip" ]; then
        ip=$(hostname -I 2>/dev/null | awk '{print $1}' || true)
    fi
    
    # Método 3: ifconfig
    if [ -z "$ip" ] && command -v ifconfig >/dev/null 2>&1; then
        ip=$(ifconfig | grep 'inet ' | grep -v '127.0.0.1' | head -1 | awk '{print $2}' || true)
    fi
    
    # Método 4: IP pública
    if [ -z "$ip" ]; then
        ip=$(curl -s --max-time 5 ifconfig.me 2>/dev/null || true)
    fi
    
    # Último recurso
    if [ -z "$ip" ]; then
        ip="localhost"
    fi
    
    echo "$ip"
}

LOCAL_IP=$(detect_ip)
log_info "IP detectada: $LOCAL_IP"

# Crear estructura de directorios
log "📁 Creando estructura de directorios..."
mkdir -p data/{matrix,postgres,ssl,logs}
mkdir -p custom-config

# Generar archivo .env si no existe
if [ ! -f .env ]; then
    log "⚙️  Creando archivo de configuración (.env)..."
    cat > .env << EOF
# Matrix Universal Docker - Configuración
# Generado automáticamente el $(date)

# Configuración del servidor
SERVER_NAME=$LOCAL_IP
DATA_PATH=$(pwd)/data

# Base de datos
POSTGRES_PASSWORD=matrix_secure_$(date +%s)

# Matrix Synapse
ENABLE_REGISTRATION=true
ENABLE_FEDERATION=false
REPORT_STATS=no

# Secreto para registro (generar nuevo)
MATRIX_REGISTRATION_SHARED_SECRET=$(openssl rand -hex 32)

# Configuración adicional
TZ=Europe/Madrid
PYTHONUNBUFFERED=1
EOF
    log_success "Archivo .env creado"
else
    log_info "Archivo .env ya existe"
fi

# Verificar archivos necesarios
log "📋 Verificando archivos del proyecto..."
required_files=("Dockerfile" "docker-compose.yml" "scripts/start-matrix.sh")
missing_files=()

for file in "${required_files[@]}"; do
    if [ ! -f "$file" ]; then
        missing_files+=("$file")
    fi
done

if [ ${#missing_files[@]} -gt 0 ]; then
    log_error "Archivos faltantes:"
    for file in "${missing_files[@]}"; do
        echo "  - $file"
    done
    log_info "Asegúrate de tener todos los archivos del proyecto"
    exit 1
fi

log_success "Todos los archivos necesarios están presentes"

# Parar contenedores existentes
log "🛑 Deteniendo contenedores existentes..."
docker-compose down --remove-orphans 2>/dev/null || true

# Construir imagen
log "🔨 Construyendo imagen Docker..."
docker-compose build --no-cache

# Iniciar servicios
log "🚀 Iniciando Matrix Universal..."
docker-compose up -d

# Esperar a que los servicios estén listos
log "⏳ Esperando que los servicios inicien..."
sleep 30

# Verificar estado
log "✅ Verificando estado de los servicios..."
if docker-compose ps | grep -q "Up"; then
    log_success "Contenedor iniciado correctamente"
else
    log_error "Error al iniciar el contenedor"
    log_info "Verificando logs..."
    docker-compose logs --tail=20
    exit 1
fi

# Verificar Matrix API
log "🔍 Verificando Matrix API..."
for i in {1..10}; do
    if curl -s --max-time 5 http://localhost:8008/_matrix/client/versions >/dev/null 2>&1; then
        log_success "Matrix API funcionando"
        break
    else
        if [ $i -eq 10 ]; then
            log_error "Matrix API no responde después de 10 intentos"
            log_info "Verificando logs del contenedor..."
            docker-compose logs matrix-universal --tail=20
            exit 1
        fi
        log "Intento $i/10 - Esperando Matrix API..."
        sleep 5
    fi
done

# Mostrar información final
echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                                                                ║${NC}"
echo -e "${GREEN}║                ✅ MATRIX UNIVERSAL DOCKER                      ║${NC}"
echo -e "${GREEN}║                        FUNCIONANDO                             ║${NC}"
echo -e "${GREEN}║                                                                ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════════╝${NC}"

echo ""
echo -e "${PURPLE}🖥️  INFORMACIÓN DEL SISTEMA:${NC}"
echo -e "   OS: $OS ($ARCH)"
echo -e "   IP: $LOCAL_IP"
echo -e "   Fecha: $(date)"

echo ""
echo -e "${YELLOW}🌐 ACCESO A MATRIX:${NC}"
echo -e "   🔒 HTTPS: ${GREEN}https://$LOCAL_IP${NC}"
echo -e "   🔓 HTTP:  ${GREEN}http://$LOCAL_IP${NC}"
echo -e "   🔧 API:   ${GREEN}http://$LOCAL_IP:8008${NC}"

echo ""
echo -e "${YELLOW}👤 CREAR PRIMER USUARIO:${NC}"
echo -e "   ${GREEN}docker exec -it matrix-universal register_matrix_user${NC}"
echo -e "   ${CYAN}O usando el script: ./scripts/create-user.sh${NC}"

echo ""
echo -e "${YELLOW}🛠️  COMANDOS ÚTILES:${NC}"
echo -e "   Ver logs:     ${GREEN}docker-compose logs -f${NC}"
echo -e "   Reiniciar:    ${GREEN}docker-compose restart${NC}"
echo -e "   Parar:        ${GREEN}docker-compose down${NC}"
echo -e "   Entrar:       ${GREEN}docker exec -it matrix-universal bash${NC}"
echo -e "   Estado:       ${GREEN}docker-compose ps${NC}"

echo ""
echo -e "${YELLOW}📁 DATOS GUARDADOS EN:${NC}"
echo -e "   $(pwd)/data/matrix   ${CYAN}(mensajes, usuarios)${NC}"
echo -e "   $(pwd)/data/postgres ${CYAN}(base de datos)${NC}"
echo -e "   $(pwd)/data/ssl      ${CYAN}(certificados)${NC}"
echo -e "   $(pwd)/data/logs     ${CYAN}(logs del sistema)${NC}"

echo ""
echo -e "${BLUE}🎉 ¡Matrix Universal Docker está listo!${NC}"
echo -e "${BLUE}   Funciona en cualquier equipo con Docker${NC}"
echo -e "${BLUE}   Datos persistentes automáticamente${NC}"
echo -e "${BLUE}   Configuración en archivo .env${NC}"

log_info "Para más información, consulta: README.md"