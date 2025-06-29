#!/bin/bash

# Matrix Universal Docker - Script de inicio
# Este script se ejecuta automáticamente al iniciar el contenedor

set -e

# Colores para logs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${BLUE}[$(date +'%H:%M:%S')]${NC} $1"; }
log_success() { echo -e "${GREEN}[$(date +'%H:%M:%S')] ✓${NC} $1"; }
log_warning() { echo -e "${YELLOW}[$(date +'%H:%M:%S')] ⚠${NC} $1"; }
log_error() { echo -e "${RED}[$(date +'%H:%M:%S')] ✗${NC} $1"; }

echo ""
echo "🚀 Matrix Universal Docker - Iniciando servicios..."
echo "=================================================="

# Variables de entorno con valores por defecto
SERVER_NAME=${SERVER_NAME:-localhost}
POSTGRES_PASSWORD=${POSTGRES_PASSWORD:-matrix_docker_2025}
ENABLE_REGISTRATION=${ENABLE_REGISTRATION:-true}
ENABLE_FEDERATION=${ENABLE_FEDERATION:-false}
MATRIX_REGISTRATION_SHARED_SECRET=${MATRIX_REGISTRATION_SHARED_SECRET:-$(openssl rand -hex 32)}
MAX_UPLOAD_SIZE=${MAX_UPLOAD_SIZE:-50}
DB_MAX_CONNECTIONS=${DB_MAX_CONNECTIONS:-10}
CACHE_FACTOR=${CACHE_FACTOR:-1.5}

log "Configuración detectada:"
log "  Server Name: $SERVER_NAME"
log "  Registration: $ENABLE_REGISTRATION"
log "  Federation: $ENABLE_FEDERATION"
log "  Max Upload: ${MAX_UPLOAD_SIZE}M"

# Función para esperar PostgreSQL
wait_for_postgres() {
    log "⏳ Esperando PostgreSQL..."
    local max_attempts=30
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if pg_isready -h localhost -p 5432 -U postgres >/dev/null 2>&1; then
            log_success "PostgreSQL está listo"
            return 0
        fi
        
        log "Intento $attempt/$max_attempts - PostgreSQL no está listo"
        sleep 2
        attempt=$((attempt + 1))
    done
    
    log_error "PostgreSQL no inició después de $max_attempts intentos"
    return 1
}

# Inicializar PostgreSQL
log "🗄️  Iniciando PostgreSQL..."
service postgresql start

# Esperar a que PostgreSQL esté listo
wait_for_postgres

# Configurar base de datos (SIN SUDO, usando su -)
log "🗄️  Configurando base de datos..."
su - postgres -c "psql -tc \"SELECT 1 FROM pg_database WHERE datname = '$POSTGRES_DB'\" | grep -q 1" || {
    log "Creando base de datos $POSTGRES_DB..."
    su - postgres -c "psql -c \"CREATE DATABASE $POSTGRES_DB ENCODING 'UTF8' LC_COLLATE='C' LC_CTYPE='C' template=template0 OWNER $POSTGRES_USER;\""
}

# Verificar usuario de base de datos
su - postgres -c "psql -tc \"SELECT 1 FROM pg_roles WHERE rolname = '$POSTGRES_USER'\" | grep -q 1" || {
    log "Creando usuario de base de datos $POSTGRES_USER..."
    su - postgres -c "psql -c \"CREATE USER $POSTGRES_USER WITH PASSWORD '$POSTGRES_PASSWORD';\""
    su - postgres -c "psql -c \"GRANT ALL PRIVILEGES ON DATABASE $POSTGRES_DB TO $POSTGRES_USER;\""
    su - postgres -c "psql -c \"ALTER USER $POSTGRES_USER CREATEDB;\""
}

log_success "Base de datos configurada"

# Generar configuración Matrix si no existe
if [ ! -f /opt/matrix/homeserver.yaml ]; then
    log "⚙️  Generando configuración inicial de Matrix..."
    
    # Crear directorio de datos
    mkdir -p /opt/matrix/data
    chown -R matrix:matrix /opt/matrix/data
    
    # Generar configuración base (SIN SUDO, usando su -)
    su - matrix -c "
        cd /opt/matrix
        source env/bin/activate
        python -m synapse.app.homeserver \
            --server-name='$SERVER_NAME' \
            --config-path='/opt/matrix/homeserver.yaml' \
            --generate-config \
            --data-directory='/opt/matrix/data' \
            --report-stats=no
    "
    
    log_success "Configuración base generada"
    
    # Personalizar configuración
    log "⚙️  Personalizando configuración..."
    
    # Backup de configuración original
    cp /opt/matrix/homeserver.yaml /opt/matrix/homeserver.yaml.backup
    
    # Configurar base de datos PostgreSQL
    cat >> /opt/matrix/homeserver.yaml << EOF

# =============================================
# CONFIGURACIÓN PERSONALIZADA
# =============================================

# PostgreSQL Database Configuration
database:
  name: psycopg2
  args:
    user: $POSTGRES_USER
    password: $POSTGRES_PASSWORD
    database: $POSTGRES_DB
    host: localhost
    port: 5432
    cp_min: 5
    cp_max: $DB_MAX_CONNECTIONS
    keepalives_idle: 10
    keepalives_interval: 10
    keepalives_count: 3

# Registration Configuration
enable_registration: $ENABLE_REGISTRATION
enable_registration_without_verification: $ENABLE_REGISTRATION
registration_shared_secret: "$MATRIX_REGISTRATION_SHARED_SECRET"

# Federation Configuration
federation_domain_whitelist: $([ "$ENABLE_FEDERATION" = "true" ] && echo "[]" || echo "[]")
federation_verify_certificates: $([ "$ENABLE_FEDERATION" = "true" ] && echo "true" || echo "false")

# Media Configuration
max_upload_size: "${MAX_UPLOAD_SIZE}M"
max_image_pixels: "32M"
dynamic_thumbnails: true

# Performance Configuration
caches:
  global_factor: $CACHE_FACTOR

# Security Configuration
password_config:
  enabled: true
  policy:
    minimum_length: 8
    require_digit: true
    require_symbol: false
    require_lowercase: true
    require_uppercase: true

# Logging Configuration
log_config: "/opt/matrix/homeserver.log.config"

# Additional Security
enable_metrics: false
allow_guest_access: false
enable_3pid_lookup: false
autocreate_auto_join_rooms: false

# Retention (disabled by default)
retention:
  enabled: false

# Presence (disabled for performance)
presence:
  enabled: false

# Push notifications
push:
  enabled: true
  include_content: true

# URL previews
url_preview_enabled: true
url_preview_ip_range_blacklist:
  - '127.0.0.0/8'
  - '10.0.0.0/8'
  - '172.16.0.0/12'
  - '192.168.0.0/16'
  - '100.64.0.0/10'
  - '169.254.0.0/16'
  - '::1/128'
  - 'fe80::/64'
  - 'fc00::/7'

EOF

    log_success "Configuración personalizada aplicada"
    
    # Generar logging config
    cat > /opt/matrix/homeserver.log.config << 'EOF'
version: 1

formatters:
  precise:
    format: '%(asctime)s - %(name)s - %(lineno)d - %(levelname)s - %(request)s - %(message)s'

handlers:
  file:
    class: logging.handlers.TimedRotatingFileHandler
    formatter: precise
    filename: /var/log/matrix/homeserver.log
    when: midnight
    backupCount: 7
    encoding: utf8
  
  console:
    class: logging.StreamHandler
    formatter: precise

root:
  level: INFO
  handlers: [file, console]

disable_existing_loggers: false
EOF

    chown matrix:matrix /opt/matrix/homeserver.log.config
    
    # Generar claves criptográficas (SIN SUDO, usando su -)
    log "🔐 Generando claves criptográficas..."
    su - matrix -c "
        cd /opt/matrix
        source env/bin/activate
        python -m synapse.app.homeserver \
            --config-path=/opt/matrix/homeserver.yaml \
            --generate-keys
    "
    
    log_success "Claves generadas"
fi

# Resto del script sin cambios...
# (Generar certificados, configurar Nginx, etc.)

# Generar certificados SSL
log "🔐 Configurando certificados SSL..."
mkdir -p /etc/ssl/matrix

if [ ! -f /etc/ssl/matrix/matrix.crt ]; then
    log "Generando certificados SSL autofirmados..."
    
    # Generar certificado con múltiples nombres
    openssl req -x509 -nodes -days 3650 -newkey rsa:4096 \
        -keyout /etc/ssl/matrix/matrix.key \
        -out /etc/ssl/matrix/matrix.crt \
        -subj "/C=ES/ST=Docker/L=Container/O=Matrix Universal/CN=$SERVER_NAME" \
        -addext "subjectAltName=DNS:localhost,DNS:matrix.local,DNS:$SERVER_NAME,IP:127.0.0.1"
    
    # Configurar permisos
    chmod 600 /etc/ssl/matrix/matrix.key
    chmod 644 /etc/ssl/matrix/matrix.crt
    
    log_success "Certificados SSL generados (válidos 10 años)"
else
    log_success "Certificados SSL ya existen"
fi

# Configurar Element Web
log "🌐 Configurando Element Web..."
cat > /var/www/element/config.json << EOF
{
    "default_server_config": {
        "m.homeserver": {
            "base_url": "https://$SERVER_NAME",
            "server_name": "$SERVER_NAME"
        }
    },
    "brand": "Matrix Universal Docker",
    "disable_custom_urls": false,
    "disable_guests": false,
    "disable_login_language_selector": false,
    "disable_3pid_login": false,
    "default_theme": "light",
    "default_federate": $ENABLE_FEDERATION,
    "features": {
        "feature_voice_messages": true,
        "feature_video_calls": true,
        "feature_audio_calls": true,
        "feature_spaces": true,
        "feature_threads": true
    },
    "showLabsSettings": true,
    "permalink_prefix": "https://$SERVER_NAME",
    "bug_report_endpoint_url": null,
    "uisi_autorageshake_app": null,
    "map_style_url": null
}
EOF

log_success "Element Web configurado"

# Configurar Nginx
log "🔧 Configurando Nginx..."
cat > /etc/nginx/sites-available/matrix << EOF
# Matrix Universal Docker - Nginx Configuration
# HTTP to HTTPS redirect
server {
    listen 80;
    server_name _;
    
    # Permitir acceso HTTP para testing
    location /_matrix {
        proxy_pass http://127.0.0.1:8008;
        proxy_set_header X-Forwarded-For \$remote_addr;
        proxy_set_header X-Forwarded-Proto http;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        
        # Configuración para WebSocket
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        
        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
    
    # Element Web
    location / {
        root /var/www/element;
        index index.html;
        try_files \$uri \$uri/ /index.html;
        
        # Headers de seguridad
        add_header X-Frame-Options SAMEORIGIN;
        add_header X-Content-Type-Options nosniff;
        add_header X-XSS-Protection "1; mode=block";
    }
    
    # Health check
    location /health {
        access_log off;
        return 200 "healthy\n";
        add_header Content-Type text/plain;
    }
}

# HTTPS server
server {
    listen 443 ssl http2;
    server_name _;

    # SSL Configuration
    ssl_certificate /etc/ssl/matrix/matrix.crt;
    ssl_certificate_key /etc/ssl/matrix/matrix.key;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-CHACHA20-POLY1305;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;

    # Security headers
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Frame-Options SAMEORIGIN;
    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection "1; mode=block";
    add_header Referrer-Policy "strict-origin-when-cross-origin";

    # Matrix Synapse
    location /_matrix {
        proxy_pass http://127.0.0.1:8008;
        proxy_set_header X-Forwarded-For \$remote_addr;
        proxy_set_header X-Forwarded-Proto https;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        
        # Configuración para WebSocket
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        
        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
        
        # Límites de carga
        client_max_body_size 50M;
    }

    # Element Web
    location / {
        root /var/www/element;
        index index.html;
        try_files \$uri \$uri/ /index.html;
        
        # Cache estático
        location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
            expires 1y;
            add_header Cache-Control "public, immutable";
        }
    }
    
    # Health check
    location /health {
        access_log off;
        return 200 "healthy\n";
        add_header Content-Type text/plain;
    }
}
EOF

# Activar sitio
ln -sf /etc/nginx/sites-available/matrix /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# Verificar configuración Nginx
if nginx -t; then
    log_success "Configuración Nginx válida"
else
    log_error "Error en configuración Nginx"
    exit 1
fi

# Configurar Supervisor para manejar procesos
log "🔧 Configurando Supervisor..."
cat > /etc/supervisor/conf.d/matrix.conf << EOF
[supervisord]
nodaemon=true
user=root
logfile=/var/log/supervisord.log
pidfile=/var/run/supervisord.pid

[program:postgresql]
command=/usr/lib/postgresql/14/bin/postgres -D /var/lib/postgresql/14/main -c config_file=/etc/postgresql/14/main/postgresql.conf
user=postgres
autorestart=true
stdout_logfile=/var/log/postgresql.log
stderr_logfile=/var/log/postgresql.log
priority=100

[program:matrix-synapse]
command=/opt/matrix/env/bin/python -m synapse.app.homeserver --config-path=/opt/matrix/homeserver.yaml
directory=/opt/matrix
user=matrix
autorestart=true
stdout_logfile=/var/log/matrix/matrix.log
stderr_logfile=/var/log/matrix/matrix.log
priority=200

[program:nginx]
command=/usr/sbin/nginx -g "daemon off;"
autorestart=true
stdout_logfile=/var/log/nginx/access.log
stderr_logfile=/var/log/nginx/error.log
priority=300
EOF

# Crear directorio de logs
mkdir -p /var/log/matrix
chown -R matrix:matrix /var/log/matrix

# Mostrar información de inicio
echo ""
echo "✅ Configuración completada"
echo "📋 Resumen de servicios:"
echo "   🗄️  PostgreSQL: localhost:5432"
echo "   🚀 Matrix Synapse: localhost:8008"
echo "   🌐 Nginx: localhost:80, localhost:443"
echo "   🎯 Element Web: Integrado"
echo ""
echo "🌐 Acceso disponible en:"
echo "   HTTP:  http://$SERVER_NAME"
echo "   HTTPS: https://$SERVER_NAME"
echo ""
echo "👤 Para crear usuarios ejecuta:"
echo "   register_matrix_user"
echo ""

log "🚀 Iniciando todos los servicios con Supervisor..."

# Iniciar Supervisor (mantiene el contenedor corriendo)
exec /usr/bin/supervisord -c /etc/supervisor/supervisord.conf