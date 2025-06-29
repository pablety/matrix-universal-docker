# Matrix Universal Docker
# Compatible con cualquier sistema que tenga Docker
# Creado por: pablety
# Fecha: 2025-06-29

FROM ubuntu:22.04

# Metadata
LABEL maintainer="pablety"
LABEL description="Matrix Synapse Universal Docker - Funciona en cualquier equipo"
LABEL version="1.0"

# Evitar prompts interactivos
ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1
ENV TZ=Europe/Madrid

# Variables de entorno por defecto
ENV MATRIX_HOME=/opt/matrix
ENV MATRIX_USER=matrix
ENV POSTGRES_DB=synapse
ENV POSTGRES_USER=synapse_user
ENV POSTGRES_PASSWORD=matrix_docker_2025
ENV SERVER_NAME=localhost
ENV ENABLE_REGISTRATION=true

# Instalar dependencias del sistema
RUN apt-get update && apt-get install -y \
    # Python y herramientas de desarrollo
    python3 python3-pip python3-venv python3-dev \
    build-essential libffi-dev libssl-dev \
    libxml2-dev libxslt1-dev libjpeg-dev \
    libpq-dev pkg-config \
    # PostgreSQL
    postgresql postgresql-contrib \
    # Servidor web
    nginx \
    # Supervisor para manejar procesos
    supervisor \
    # Utilidades
    wget curl git nano openssl ca-certificates \
    htop tree unzip jq \
    # Limpieza
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /tmp/* \
    && rm -rf /var/tmp/*

# Crear usuario matrix
RUN groupadd -r matrix \
    && useradd -r -g matrix -d $MATRIX_HOME -s /bin/bash matrix \
    && mkdir -p $MATRIX_HOME \
    && chown -R matrix:matrix $MATRIX_HOME

# Instalar Matrix Synapse
USER matrix
WORKDIR $MATRIX_HOME
RUN python3 -m venv env \
    && . env/bin/activate \
    && pip install --no-cache-dir --upgrade pip setuptools wheel \
    && pip install --no-cache-dir matrix-synapse[all] psycopg2-binary \
    && pip install --no-cache-dir jinja2-cli

# Volver a root para configuraciones del sistema
USER root

# Crear directorios necesarios
RUN mkdir -p /var/www/element \
    && mkdir -p /etc/ssl/matrix \
    && mkdir -p /var/log/matrix \
    && mkdir -p /opt/scripts \
    && mkdir -p /opt/configs \
    && chown -R matrix:matrix /var/log/matrix

# Descargar Element Web
RUN cd /tmp \
    && ELEMENT_VERSION="v1.11.69" \
    && wget -q "https://github.com/vector-im/element-web/releases/download/${ELEMENT_VERSION}/element-${ELEMENT_VERSION}.tar.gz" \
    && tar -xzf "element-${ELEMENT_VERSION}.tar.gz" \
    && cp -r element-${ELEMENT_VERSION}/* /var/www/element/ \
    && chown -R www-data:www-data /var/www/element \
    && rm -rf /tmp/*

# Configurar PostgreSQL
RUN service postgresql start \
    && sleep 5 \
    && sudo -u postgres psql -c "CREATE USER ${POSTGRES_USER} WITH PASSWORD '${POSTGRES_PASSWORD}';" \
    && sudo -u postgres psql -c "CREATE DATABASE ${POSTGRES_DB} ENCODING 'UTF8' LC_COLLATE='C' LC_CTYPE='C' template=template0 OWNER ${POSTGRES_USER};" \
    && sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE ${POSTGRES_DB} TO ${POSTGRES_USER};" \
    && sudo -u postgres psql -c "ALTER USER ${POSTGRES_USER} CREATEDB;" \
    && service postgresql stop

# Copiar archivos de configuración y scripts
COPY scripts/ /opt/scripts/
COPY configs/ /opt/configs/

# Hacer scripts ejecutables
RUN chmod +x /opt/scripts/*.sh

# Configurar Nginx (remover configuración por defecto)
RUN rm -f /etc/nginx/sites-enabled/default \
    && rm -f /etc/nginx/sites-available/default

# Crear script de registro de usuarios
RUN echo '#!/bin/bash' > /usr/local/bin/register_matrix_user \
    && echo 'sudo -u matrix /opt/matrix/env/bin/register_new_matrix_user -c /opt/matrix/homeserver.yaml http://localhost:8008 "$@"' >> /usr/local/bin/register_matrix_user \
    && chmod +x /usr/local/bin/register_matrix_user

# Exponer puertos
EXPOSE 80 443 8008 5432

# Volúmenes para persistencia
VOLUME ["/opt/matrix/data", "/var/lib/postgresql", "/etc/ssl/matrix", "/var/log"]

# Healthcheck
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:8008/_matrix/client/versions || exit 1

# Script de inicio
ENTRYPOINT ["/opt/scripts/start-matrix.sh"]